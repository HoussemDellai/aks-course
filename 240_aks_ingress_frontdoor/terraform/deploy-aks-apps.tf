resource "terraform_data" "deploy-apps-to-aks" {
  triggers_replace = [
    azurerm_kubernetes_cluster.aks.id
  ]

  provisioner "local-exec" {
    command = "kubectl apply -f ../kubernetes"
  }

  depends_on = [ terraform_data.aks-get-credentials ]
}