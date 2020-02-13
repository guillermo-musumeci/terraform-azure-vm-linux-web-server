#############################################
## Azure Linux VM with Web Module - Output ##
#############################################

output "web_vm_name" {
  description = "Virtual Machine name"
  value       = azurerm_virtual_machine.web-vm.name
}

output "web_vm_ip_address" {
  description = "Virtual Machine name IP Address"
  value       = azurerm_public_ip.web-vm-ip.ip_address
}

output "web_vm_admin_username" {
  description = "Username password for the Virtual Machine"
  value       = azurerm_virtual_machine.web-vm.os_profile.*
  #sensitive   = true
}

output "web_vm_admin_password" {
  description = "Administrator password for the Virtual Machine"
  value       = random_password.web-vm-password.result
  #sensitive   = true
}

