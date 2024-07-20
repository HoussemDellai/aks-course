# Get the PLS that is created for the ingress and the service
data "azurerm_private_link_service" "pls-ingress" {
  name                = var.pls_ingress_name
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group

  depends_on = [time_sleep.wait_120_seconds]
}

data "azurerm_private_link_service" "pls-service" {
  name                = var.pls_service_name
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group

  depends_on = [time_sleep.wait_120_seconds]
}

resource "time_sleep" "wait_120_seconds" {
  depends_on = [terraform_data.deploy-apps-to-aks]

  create_duration = "180s"
}