resource "azurerm_user_assigned_identity" "identity-aks-app" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "identity-aks-app"
}

resource "azurerm_federated_identity_credential" "federated-cred" {
  name                = "federated-cred"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.identity-aks-app.id
  subject             = "system:serviceaccount:default:sacc"
}

resource "azurerm_role_assignment" "storage-blob-data-reader" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.identity-aks-app.principal_id
}
