resource "terraform_data" "app-routing-add-dns-zone" {
  triggers_replace = [
    azurerm_kubernetes_cluster.aks.id,
    azurerm_private_dns_zone.private_dns_zone.id
  ]

  provisioner "local-exec" {
    command = "az aks approuting zone add -n ${azurerm_kubernetes_cluster.aks.name} -g ${azurerm_kubernetes_cluster.aks.resource_group_name} --ids=${azurerm_private_dns_zone.private_dns_zone.id} --attach-zones"
  }
}