resource "azurerm_container_app" "aca_app1" {
  name                         = "aca-app1"
  container_app_environment_id = azurerm_container_app_environment.aca_environment.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "app1"
      image  = "${azurerm_container_registry.acr.login_server}/team1/app1:v1"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity_aca_app1.id]
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

resource "azurerm_user_assigned_identity" "identity_aca_app1" {
  name                = "identity-aca-app1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

output "app1_url" {
  value = azurerm_container_app.aca_app1.latest_revision_fqdn
}

