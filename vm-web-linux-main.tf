###########################################
## Azure Linux VM with Web Module - Main ##
###########################################

# Generate random password
resource "random_password" "web-vm-password" {
  length           = 16
  min_upper        = 2
  min_lower        = 2
  min_special      = 2
  number           = true
  special          = true
  override_special = "!@#$%&"
}

# Generate a random vm name
resource "random_string" "web-vm-name" {
  length  = 8
  upper   = false
  number  = false
  lower   = true
  special = false
}

# Create Security Group to access web
resource "azurerm_network_security_group" "web-vm-nsg" {
  depends_on=[azurerm_resource_group.network-rg]

  name                = "web-${lower(var.environment)}-${random_string.web-vm-name.result}-nsg"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name

  security_rule {
    name                       = "AllowWEB"
    description                = "Allow web"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    description                = "Allow SSH"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  tags = {
    environment = var.environment
  }
}

# Associate the web NSG with the subnet
resource "azurerm_subnet_network_security_group_association" "web-vm-nsg-association" {
  depends_on=[azurerm_resource_group.network-rg]

  subnet_id                 = azurerm_subnet.network-subnet.id
  network_security_group_id = azurerm_network_security_group.web-vm-nsg.id
}

# Get a Static Public IP
resource "azurerm_public_ip" "web-vm-ip" {
  depends_on=[azurerm_resource_group.network-rg]

  name                = "web-${random_string.web-vm-name.result}-ip"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  allocation_method   = "Static"
  
  tags = { 
    environment = var.environment
  }
}

# Create Network Card for web VM
resource "azurerm_network_interface" "web-private-nic" {
  depends_on=[azurerm_resource_group.network-rg]

  name                = "web-${random_string.web-vm-name.result}-nic"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.network-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web-vm-ip.id
  }

  tags = { 
    environment = var.environment
  }
}

# Create Linux VM with web server
resource "azurerm_virtual_machine" "web-vm" {
  depends_on=[azurerm_network_interface.web-private-nic]

  location              = azurerm_resource_group.network-rg.location
  resource_group_name   = azurerm_resource_group.network-rg.name
  name                  = "web-${random_string.web-vm-name.result}-vm"
  network_interface_ids = [azurerm_network_interface.web-private-nic.id]
  vm_size               = var.web_vm_size
  license_type          = var.web_license_type

  delete_os_disk_on_termination    = var.web_delete_os_disk_on_termination
  delete_data_disks_on_termination = var.web_delete_data_disks_on_termination

  storage_image_reference {
    id        = lookup(var.web_vm_image, "id", null)
    offer     = lookup(var.web_vm_image, "offer", null)
    publisher = lookup(var.web_vm_image, "publisher", null)
    sku       = lookup(var.web_vm_image, "sku", null)
    version   = lookup(var.web_vm_image, "version", null)
  }

  storage_os_disk {
    name              = "web-${random_string.web-vm-name.result}-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "web-${random_string.web-vm-name.result}-vm"
    admin_username = var.web_admin_username
    admin_password = random_password.web-vm-password.result
    custom_data    = file("azure-user-data.sh")
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = var.environment
  }
}