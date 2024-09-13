output "rg_name" {
  value = azurerm_resource_group.rg.name
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.vm.id
}