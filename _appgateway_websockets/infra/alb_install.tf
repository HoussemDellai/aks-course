resource "terraform_data" "install_alb_into_aks" {
  triggers_replace = [
    azurerm_kubernetes_cluster.aks.id
  ]

  provisioner "local-exec" {
    # command = "az aks update --name ${azurerm_kubernetes_cluster.aks.name} --resource-group ${azurerm_kubernetes_cluster.aks.resource_group_name} --enable-gateway-api --enable-application-load-balancer"
    command = "helm upgrade alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller --install --namespace azure-alb-system --create-namespace --version 1.9.13 --set albController.namespace=azure-alb-system --set albController.podIdentity.clientID=${azurerm_user_assigned_identity.identity-alb.client_id}"
  }

  depends_on = [ terraform_data.aks-get-credentials ]
}