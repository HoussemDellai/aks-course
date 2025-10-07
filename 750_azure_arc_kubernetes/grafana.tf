resource "azurerm_dashboard_grafana" "grafana" {
  name                              = "grafana-${var.prefix}"
  resource_group_name               = azurerm_resource_group.rg.name
  location                          = azurerm_resource_group.rg.location
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = true
  public_network_access_enabled     = true
  sku                               = "Standard"
  zone_redundancy_enabled           = false
  grafana_major_version             = "11"

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.prometheus.id
  }

  identity {
    type = "SystemAssigned"
  }
}

# # might need : az extension add --name amg
# resource "terraform_data" "import-grafana-dashboard" {
#   triggers_replace = [azurerm_dashboard_grafana.grafana.0.id]

#   provisioner "local-exec" {
#     command = "az grafana dashboard import -n ${azurerm_dashboard_grafana.grafana.0.name} -g ${azurerm_dashboard_grafana.grafana.0.resource_group_name} --definition 18814"
#   }

#   depends_on = [azurerm_role_assignment.role_grafana_admin]
# }

resource "azurerm_role_assignment" "role_grafana_admin" {
  scope                = azurerm_dashboard_grafana.grafana.id
  role_definition_name = "Grafana Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "role_monitoring_data_reader" {
  scope                = azurerm_monitor_workspace.prometheus.id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.grafana.identity.0.principal_id
}

# https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/grafana-plugin
# to monitor all Azure resources
resource "azurerm_role_assignment" "role_monitoring_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.grafana.identity.0.principal_id
}
