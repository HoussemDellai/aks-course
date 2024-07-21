resource "azurerm_api_management" "apim" {
  name                          = "apim-public-${var.prefix}"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  publisher_name                = "My Company"
  publisher_email               = "houssem.dellai@live.com"
  sku_name                      = "Developer_1"
  virtual_network_type          = "None" # External, Internal
  public_network_access_enabled = true # false applies only when using private endpoint as the exclusive access method
}