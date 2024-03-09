# use AzAPI to create Grafana Managed Private Endpoint

resource "azapi_resource" "mpe-grafana" {
  type      = "microsoft.dashboard/grafana/managedprivateendpoints@2023-09-01"
  name      = "mpe-grafana"
  parent_id = azurerm_dashboard_grafana.grafana.id
  location  = azurerm_dashboard_grafana.grafana.location

  body = jsonencode({
    properties = {
      privateLinkResourceId : azurerm_monitor_workspace.prometheus.id,
      privateLinkResourceRegion : azurerm_monitor_workspace.prometheus.location,
      groupIds : ["prometheusMetrics"],
      requestMessage : "Please approve for Grafana to connect to Prometheus"
    }
  })
}

# Retrieve the Managed Private Endpoints (MPE)
data "azapi_resource_list" "mpe-grafana" {
  type                   = "Microsoft.Monitor/accounts/privateEndpointConnections@2023-04-03"
  parent_id              = azurerm_monitor_workspace.prometheus.id
  response_export_values = ["*"]
}

# Retrieve the Grafana's Managed Private Endpoint ID
locals {
  mpe-grafana-id = element([for pe in jsondecode(data.azapi_resource_list.mpe-grafana.output).value : pe.id if pe.properties.privateLinkServiceConnectionState.status == "Pending"], 0) # strcontains(pe.id, azapi_resource.mpe-grafana.name)], 0)
}

# Approve Grafana's Managed Private Endpoint connection to Prometheus
resource "azapi_update_resource" "approve-mpe-grafana" {
  type        = "Microsoft.Monitor/accounts/privateEndpointConnections@2023-04-03"
  resource_id = local.mpe-grafana-id

  body = jsonencode({
    properties = {
      privateLinkServiceConnectionState = {
        status : "Approved"
        description : "Approved by Terraform"
      }
    }
  })
}
