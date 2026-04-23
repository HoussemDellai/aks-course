resource "terraform_data" "aks_get_credentials" {
  triggers_replace = [
    azurerm_kubernetes_cluster.aks_1.id
  ]

  provisioner "local-exec" {
    # interpreter = ["PowerShell", "-Command"]
    command = <<-EOT
      az aks get-credentials -g ${azurerm_kubernetes_cluster.aks_1.resource_group_name} -n ${azurerm_kubernetes_cluster.aks_1.name} --overwrite-existing
    EOT
  }
}