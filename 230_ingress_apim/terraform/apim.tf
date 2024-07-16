resource "azurerm_public_ip" "pip-apim" {
  name                = "pip-apim"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
  domain_name_label   = "apim-external-${var.prefix}"
}

resource "azurerm_api_management" "apim" {
  name                          = "apim-external-aks-${var.prefix}"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  publisher_name                = "My Company"
  publisher_email               = "houssem.dellai@live.com"
  sku_name                      = "Developer_1"
  virtual_network_type          = "External" # None, External, Internal
  public_ip_address_id          = azurerm_public_ip.pip-apim.id
  public_network_access_enabled = true # false applies only when using private endpoint as the exclusive access method

  virtual_network_configuration {
    subnet_id = azurerm_subnet.snet-apim.id
  }

  depends_on = [azurerm_subnet_network_security_group_association.nsg-association]
}