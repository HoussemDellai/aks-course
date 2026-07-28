resource "azurerm_user_assigned_identity" "identity_wi" {
  name                = "identity-wi"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_role_assignment" "role_identity_wi_storage_blob_data_owner" {
  scope                            = azurerm_storage_account.sa.id
  role_definition_name             = "Storage Blob Data Owner"
  principal_id                     = azurerm_user_assigned_identity.identity_wi.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "storage_account_contributor_wi" {
  principal_id         = azurerm_user_assigned_identity.identity_wi.principal_id
  role_definition_name = "Storage Account Contributor"
  scope                = azurerm_storage_account.sa.id
}

resource "azurerm_role_assignment" "storage_blob_data_contributor_wi" {
  principal_id         = azurerm_user_assigned_identity.identity_wi.principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.sa.id
}

resource "azurerm_federated_identity_credential" "identity_wi" {
  name                      = "federated-identity-credential-wi"
  user_assigned_identity_id = azurerm_user_assigned_identity.identity_wi.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject                   = "system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"
}