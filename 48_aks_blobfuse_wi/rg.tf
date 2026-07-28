
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = "italynorth" # "swedencentral"

  tags = {
    SecurityControl = "Ignore"
  }
}