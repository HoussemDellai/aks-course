resource "azurerm_resource_group" "rg-spoke" {
  

  name     = "rg-spoke-${var.prefix}-${var.spoke}"
  location = var.location
}
