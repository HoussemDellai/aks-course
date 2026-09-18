output "clusters" {
  description = "AKS and Arc resource details for each environment."
  value = {
    for environment, cluster in azurerm_kubernetes_cluster.cluster : environment => {
      resource_group = cluster.resource_group_name
      aks_name       = cluster.name
      aks_id         = cluster.id
      arc_name       = terraform_data.arc[environment].input.arc_name
      arc_id         = "${azurerm_resource_group.environment[environment].id}/providers/Microsoft.Kubernetes/connectedClusters/${terraform_data.arc[environment].input.arc_name}"
      portal_url     = "https://portal.azure.com/#resource${azurerm_resource_group.environment[environment].id}/overview"
    }
  }
}