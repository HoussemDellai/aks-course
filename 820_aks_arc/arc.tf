resource "terraform_data" "arc" {
  for_each = local.environments

  input = {
    subscription_id = data.azurerm_client_config.current.subscription_id
    resource_group  = azurerm_resource_group.environment[each.key].name
    cluster_name    = azurerm_kubernetes_cluster.cluster[each.key].name
    arc_name        = "arc-${var.prefix}-${each.key}"
    location        = azurerm_resource_group.environment[each.key].location
    environment     = each.key
    script_path     = "${path.module}/scripts/arc.ps1"
  }

  triggers_replace = [
    azurerm_kubernetes_cluster.cluster[each.key].id,
    "arc-${var.prefix}-${each.key}",
  ]

  provisioner "local-exec" {
    command     = "& $env:ARC_SCRIPT -Action Connect"
    interpreter = ["pwsh", "-NoProfile", "-NonInteractive", "-Command"]
    environment = {
      ARC_SCRIPT          = self.input.script_path
      ARC_SUBSCRIPTION_ID = self.input.subscription_id
      ARC_RESOURCE_GROUP  = self.input.resource_group
      ARC_AKS_NAME        = self.input.cluster_name
      ARC_NAME            = self.input.arc_name
      ARC_LOCATION        = self.input.location
      ARC_ENVIRONMENT     = self.input.environment
    }
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "& $env:ARC_SCRIPT -Action Disconnect"
    interpreter = ["pwsh", "-NoProfile", "-NonInteractive", "-Command"]
    environment = {
      ARC_SCRIPT          = self.input.script_path
      ARC_SUBSCRIPTION_ID = self.input.subscription_id
      ARC_RESOURCE_GROUP  = self.input.resource_group
      ARC_AKS_NAME        = self.input.cluster_name
      ARC_NAME            = self.input.arc_name
      ARC_LOCATION        = self.input.location
      ARC_ENVIRONMENT     = self.input.environment
    }
  }
}