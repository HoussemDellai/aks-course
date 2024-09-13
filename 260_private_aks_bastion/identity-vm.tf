resource "azurerm_user_assigned_identity" "identity" {
  name                = "identity-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_role_assignment" "vm-contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

data "azurerm_subscription" "current" {}