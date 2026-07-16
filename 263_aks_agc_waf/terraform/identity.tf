resource "azurerm_user_assigned_identity" "alb" {
  name = "uai-alb-controller"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
