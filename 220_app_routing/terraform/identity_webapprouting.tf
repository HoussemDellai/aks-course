data "azurerm_user_assigned_identity" "webapp_routing" {
  #   name                = "webapprouting-${azurerm_kubernetes_cluster.aks.name}"
  name                = split("/", azurerm_kubernetes_cluster.aks.web_app_routing.0.web_app_routing_identity.0.user_assigned_identity_id)[8]
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
}

resource "azurerm_role_assignment" "key-vault-secrets-user" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_user_assigned_identity.webapp_routing.principal_id
}

resource "azurerm_role_assignment" "dns-zone-contributor" {
  scope                = azurerm_dns_zone.dns_zone.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = data.azurerm_user_assigned_identity.webapp_routing.principal_id
}