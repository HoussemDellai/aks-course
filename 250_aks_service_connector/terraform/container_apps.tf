resource "azurerm_container_app" "app-dedicated" {
  name                         = "nginx-dedicated"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_container_app_environment.env.resource_group_name
  revision_mode                = "Single"
  workload_profile_name        = "profile-D4"

  template {
    min_replicas = 1
    max_replicas = 3
    container {
      name   = "nginx"
      image  = "nginx"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    allow_insecure_connections = true
    external_enabled           = true
    target_port                = 80
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

resource "azurerm_container_app" "app-consumption" {
  name                         = "nginx-consumption"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_container_app_environment.env.resource_group_name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  template {
    min_replicas = 1
    max_replicas = 3
    container {
      name   = "nginx"
      image  = "nginx"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    allow_insecure_connections = true
    external_enabled           = true
    target_port                = 80
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}