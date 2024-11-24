resource "azapi_resource" "nodepool-egress" {
  type                      = "Microsoft.ContainerService/managedClusters/agentPools@2024-09-02-preview"
  parent_id                 = azurerm_kubernetes_cluster.aks.id
  name                      = "npegresspr"
  schema_validation_enabled = false

  body = {
    properties = {
      count  = 2
      mode   = "Gateway"
      vmSize = "standard_d2pds_v6"
      nodeTaints = [
        "kubernetes.azure.com/mode=gateway:NoSchedule"
      ]
      nodeLabels = {
        "kubeegressgateway.azure.com/mode" = "true"
      }
    }
  }

  depends_on = [azapi_update_resource.enable-aks-static-egress-gateway]
}
