resource "azurerm_container_registry" "acr" {
  name                          = "acr4aks4dev"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = true
  zone_redundancy_enabled       = false
  anonymous_pull_enabled        = false
  data_endpoint_enabled         = false
  network_rule_bypass_option    = "AzureServices"

  georeplications {
    location                = "westeurope"
    zone_redundancy_enabled = true
    tags                    = {}
  }

  # georeplications {
  #   location                = "northeurope"
  #   zone_redundancy_enabled = true
  #   tags                    = {}
  # }

  network_rule_set {
      default_action = "Deny"

      ip_rule {
        action   = "Allow"
        ip_range = "176.177.25.47/32"
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
}

# resource "azurerm_role_assignment" "acrpull" {
#   principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
#   role_definition_name             = "AcrPull"
#   scope                            = azurerm_container_registry.acr.id
#   skip_service_principal_aad_check = true
# }