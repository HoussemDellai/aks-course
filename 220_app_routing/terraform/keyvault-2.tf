resource "azurerm_key_vault" "keyvault2" {
  name                          = "kv42aks${var.prefix}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  enabled_for_disk_encryption   = false
  public_network_access_enabled = true
  sku_name                      = "standard"
  enable_rbac_authorization     = true
}

resource "azurerm_key_vault_certificate" "aks-ingress-tls-012" {
  name         = "aks-ingress-tls-01"
  key_vault_id = azurerm_key_vault.keyvault2.id

  certificate {
    contents = filebase64("../cert/aks-ingress-tls.pfx")
    password = ""
  }

  depends_on = [ azurerm_role_assignment.keyvault-secrets-officer2 ]
}

resource "azurerm_role_assignment" "keyvault-secrets-officer2" {
  scope                = azurerm_key_vault.keyvault2.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "key-vault-secrets-user2" {
  scope                = azurerm_key_vault.keyvault2.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_user_assigned_identity.webapp_routing.principal_id
}