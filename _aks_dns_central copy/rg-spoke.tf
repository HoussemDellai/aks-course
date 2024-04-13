resource "azurerm_resource_group" "rg-spoke" {
  for_each = tomap(var.spokes)

  name     = "rg-spoke-${var.prefix}-${each.key}"
  location = var.location
}
