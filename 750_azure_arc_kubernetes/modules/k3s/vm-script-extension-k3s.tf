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
      "commandToExecute": "bash install-k3s-msi.sh ${azurerm_linux_virtual_machine.vm_linux_k3s.admin_username} ${var.client_id} ${var.client_secret} ${var.tenant_id} ${azurerm_linux_virtual_machine.vm_linux_k3s.name} ${azurerm_linux_virtual_machine.vm_linux_k3s.resource_group_name} ${azurerm_resource_group.rg.location} ${local.template_base_url} ${var.prometheus_resource_id} ${var.grafana_resource_id} ${var.prometheus_resource_id} ${var.grafana_resource_id} ${var.log_analytics_resource_id}"
    }
PROTECTED_SETTINGS


  timeouts {
    create = "60m"
  }

  lifecycle {
    ignore_changes = [
      protected_settings
    ]
  }

  depends_on = [
    azurerm_role_assignment.vm_contributor_on_subscription,
    azurerm_virtual_network_peering.vnet-peering-hub-to-spoke,
    azurerm_virtual_network_peering.vnet-peering-spoke-to-hub
    ]
}

# # resource assignment
# resource "azurerm_role_assignment" "role_aks_admin" {
#   scope                = "/subscriptions/dcef7009-6b94-4382-afdc-17eb160d709a/resourceGroups/rg-arc-k8s-francecentral-750-001/providers/Microsoft.Kubernetes/connectedClusters/vm-ubuntu-k3s-francecentral-750-001"
#   role_definition_name = "Azure Arc Kubernetes Cluster Admin"
#   principal_id         = data.azurerm_client_config.current.object_id
# }

# data "azurerm_client_config" "current" {}