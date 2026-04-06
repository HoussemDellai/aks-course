resource "terraform_data" "acr-docker-login" {
  triggers_replace = [
    azurerm_container_registry.acr.id
  ]

  provisioner "local-exec" {
    # interpreter = ["PowerShell", "-Command"]
    command = <<-EOT
      az acr login -n ${azurerm_container_registry.acr.name} --expose-token
    EOT
  }
}