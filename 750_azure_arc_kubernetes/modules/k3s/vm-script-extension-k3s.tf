resource "azurerm_virtual_machine_extension" "custom_script" {
  name                       = "sce"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm_linux_k3s.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  auto_upgrade_minor_version = true

  protected_settings = <<PROTECTED_SETTINGS
    {
      "fileUris": [
          "${local.template_base_url}scripts/install-k3s-msi.sh"
      ],
      "commandToExecute": "bash install-k3s-msi.sh ${azurerm_linux_virtual_machine.vm_linux_k3s.admin_username} ${var.client_id} ${var.client_secret} ${var.tenant_id} ${azurerm_linux_virtual_machine.vm_linux_k3s.name} ${azurerm_linux_virtual_machine.vm_linux_k3s.resource_group_name} ${azurerm_resource_group.rg.location} ${local.template_base_url}"
    }
PROTECTED_SETTINGS


  timeouts {
    create = "60m"
  }

  depends_on = [azurerm_role_assignment.vm_contributor_on_subscription]
}