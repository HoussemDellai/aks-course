resource "terraform_data" "install-alb-into-aks" {
  triggers_replace = [
    azurerm_kubernetes_cluster.aks.id
  ]

  provisioner "local-exec" {
    command = "helm upgrade alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller --install --namespace aks-cluster --create-namespace --version 1.4.14 --set albController.namespace=azure-alb-system --set albController.podIdentity.clientID=${azurerm_user_assigned_identity.identity-alb.client_id}"
  }
}