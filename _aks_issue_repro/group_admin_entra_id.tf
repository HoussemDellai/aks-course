resource "azuread_group" "aks_cluster_admins" {
  display_name     = "aks-cluster-admins"
  security_enabled = true
  owners           = [data.azuread_client_config.current.object_id]

  members = [
    data.azuread_client_config.current.object_id
  ]
}

data "azuread_client_config" "current" {}