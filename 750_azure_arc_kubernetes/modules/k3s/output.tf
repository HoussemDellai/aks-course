output "vm_pip" {
  value = azurerm_public_ip.pip_vm.ip_address
}

output "vm_private_ip" {
  value = azurerm_network_interface.nic_vm.private_ip_address
}
