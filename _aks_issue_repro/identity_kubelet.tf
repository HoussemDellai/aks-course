resource "azurerm_user_assigned_identity" "identity_kubelet" {
  name                = "identity-kubelet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}