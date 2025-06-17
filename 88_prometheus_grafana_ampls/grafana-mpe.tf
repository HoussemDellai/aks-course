# use AzAPI to create Grafana Managed Private Endpoint

resource "azurerm_dashboard_grafana_managed_private_endpoint" "mpe-grafana" {
  grafana_id                   = azurerm_dashboard_grafana.grafana.id
  name                         = "mpe-grafana"
  location                     = azurerm_dashboard_grafana.grafana.location
  private_link_resource_id     = azurerm_monitor_workspace.prometheus.id
  group_ids                    = ["prometheusMetrics"]
  private_link_resource_region = azurerm_dashboard_grafana.grafana.location
  request_message              = "Please approve for Grafana to connect to Prometheus"
}

# resource "azapi_resource" "mpe-grafana" {
#   type      = "microsoft.dashboard/grafana/managedprivateendpoints@2023-09-01"
#   name      = "mpe-grafana"
#   parent_id = azurerm_dashboard_grafana.grafana.id
#   location  = azurerm_dashboard_grafana.grafana.location

#   body = jsonencode({
#     properties = {
#       privateLinkResourceId : azurerm_monitor_workspace.prometheus.id,
#       privateLinkResourceRegion : azurerm_monitor_workspace.prometheus.location,
#       groupIds : ["prometheusMetrics"],
#       requestMessage : "Please approve for Grafana to connect to Prometheus"
#     }
#   })
# }

# # Retrieve the Managed Private Endpoints (MPE)
# data "azapi_resource_list" "mpe-grafana" {
#   type                   = "Microsoft.Monitor/accounts/privateEndpointConnections@2023-04-03"
#   parent_id              = azurerm_monitor_workspace.prometheus.id
#   response_export_values = ["*"]
#   depends_on             = [azapi_resource.mpe-grafana]
# }

# the actual azurerm_monitor_workspace resource doesn't yet export the private endpoint connections information
# so we use the azapi provider to get that (once they've been created, otherwise things fail)
data "azapi_resource" "azurerm_monitor_workspace" {
  type                   = "Microsoft.Monitor/accounts@2023-04-03"
  resource_id            = azurerm_monitor_workspace.prometheus.id
  response_export_values = ["properties.privateEndpointConnections"]
  depends_on             = [azurerm_dashboard_grafana_managed_private_endpoint.mpe-grafana]
}

# Retrieve the private endpoint connection name from the monitor account based on the private endpoint name
locals {
  private_endpoint_connection_name = element([
    for connection in data.azapi_resource.azurerm_monitor_workspace.output.properties.privateEndpointConnections
    : connection.name
    # if connection.properties.privateLinkServiceConnectionState.status == "Pending"
    if endswith(connection.properties.privateEndpoint.id, "grafana-${azurerm_dashboard_grafana.grafana.name}-${azurerm_dashboard_grafana_managed_private_endpoint.mpe-grafana.name}")
  ], 0)
}

# Retrieve the Grafana's Managed Private Endpoint ID
# locals {
#   # mpe-grafana-id = element([for pe in jsondecode(data.azapi_resource_list.mpe-grafana.output).value : pe.id if pe.properties.privateLinkServiceConnectionState.status == "Pending"], 0)
#   # mpe-grafana-id = element([for pe in jsondecode(data.azapi_resource_list.mpe-grafana.output).value : pe.id if strcontains(pe.id, azapi_resource.mpe-grafana.name)], 0)
#   mpe-grafana-id = try(element([for pe in data.azapi_resource_list.mpe-grafana.output.value : pe.id if pe.properties.privateLinkServiceConnectionState.status == "Pending"], 0), null)
# }

# Approve Grafana's Managed Private Endpoint connection to Prometheus
resource "azapi_update_resource" "approve-mpe-grafana-connection" {
  # count       = local.mpe-grafana-id != null ? 1 : 0
  type      = "Microsoft.Monitor/accounts/privateEndpointConnections@2023-04-03"
  name      = local.private_endpoint_connection_name
  parent_id = azurerm_monitor_workspace.prometheus.id
  # resource_id = local.private_endpoint_connection_name # local.mpe-grafana-id

  body = {
    properties = {
      privateLinkServiceConnectionState = {
        actions_required = "None"
        status           = "Approved"
        description      = "Approved by Terraform"
      }
    }
  }
}
