resource "azurerm_user_assigned_identity" "identity_aks" {
  name                = "identity-aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_role_assignment" "role_identity_aks_network_contributor" {
  scope                            = azurerm_virtual_network.vnet_spoke.id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.identity_aks.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "role_identity_aks_network_contributor_subnet_apiserver" {
  scope                            = azurerm_subnet.snet_aks_apiserver.id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_user_assigned_identity.identity_aks.principal_id
  skip_service_principal_aad_check = true
}