resource "terraform_data" "deploy-app-to-aks" {
  triggers_replace = [
    azurerm_kubernetes_cluster.aks.id
  ]

  provisioner "local-exec" {
    command = "kubectl apply -f ../kubernetes/app.yaml"
  }

  depends_on = [ terraform_data.aks-get-credentials ]
}