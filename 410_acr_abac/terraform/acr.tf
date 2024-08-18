resource "azurerm_container_registry" "acr" {
  name                          = "acr11abac"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  sku                           = "Standard"
  admin_enabled                 = false
  public_network_access_enabled = true
  zone_redundancy_enabled       = false
  anonymous_pull_enabled        = false
  data_endpoint_enabled         = false
  network_rule_bypass_option    = "AzureServices"
}

# az acr update -n $ACR_NAME -g $RG_NAME --role-assignment-mode AbacRepositoryPermissions
resource "azapi_update_resource" "anable_acr_abac" {
  type        = "Microsoft.ContainerRegistry/registries@2024-01-01-preview"
  resource_id = azurerm_container_registry.acr.id

  body = {
    properties = {
      roleAssignmentMode = "AbacRepositoryPermissions"
    }
  }
}

resource "terraform_data" "acr_import_app1" {
  triggers_replace = [
    azurerm_container_registry.acr.id
  ]

  provisioner "local-exec" {
    command = "az acr import --name ${azurerm_container_registry.acr.name} --source ghcr.io/jelledruyts/inspectorgadget:latest --image team1/app1:v1"
  }

  depends_on = [azapi_update_resource.anable_acr_abac]
}

resource "terraform_data" "acr_import_app2" {
  triggers_replace = [
    azurerm_container_registry.acr.id
  ]

  provisioner "local-exec" {
    command = "az acr import --name ${azurerm_container_registry.acr.name} --source ghcr.io/jelledruyts/inspectorgadget:latest --image team2/app2:v1"
  }

  depends_on = [azapi_update_resource.anable_acr_abac]
}

# role assignment for current user

resource "azurerm_role_assignment" "acr-lister" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "ACR Registry Catalog Lister"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "acr-contributor" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "ACR Repository Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

data "azurerm_client_config" "current" {}