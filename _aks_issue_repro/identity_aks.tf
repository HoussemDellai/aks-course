resource "azurerm_user_assigned_identity" "identity_aks" {
  name                = "identity-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "network_contributor" {
  scope                = azurerm_subnet.snet_aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.identity_aks.principal_id
}

# Managed Identity Operator
resource "azurerm_role_assignment" "managed_identity_operator" {
  scope                = azurerm_user_assigned_identity.identity_kubelet.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.identity_aks.principal_id
}