resource "azurerm_user_assigned_identity" "identity-aks" {
  name                = "identity-aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_role_assignment" "network-contributor" {
  scope                            = azurerm_virtual_network.vnet.id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.identity-aks.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "contributor" {
  scope                            = azurerm_resource_group.rg.id
  role_definition_name             = "Contributor"
  principal_id                     = azurerm_user_assigned_identity.identity-aks.principal_id
  skip_service_principal_aad_check = true
}

# resource "azurerm_role_assignment" "Managed-Identity-Operator" {
#   scope                            = azurerm_user_assigned_identity.identity-kubelet.id
#   role_definition_name             = "Managed Identity Operator"
#   principal_id                     = azurerm_user_assigned_identity.identity_aks.principal_id
#   skip_service_principal_aad_check = true
# }
