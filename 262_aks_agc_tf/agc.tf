resource "azurerm_application_load_balancer" "agc" {
  name                = "agc-aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}
 
resource "azurerm_application_load_balancer_subnet_association" "agc_snet_association" {
  name                         = "agc-snet-association"
  application_load_balancer_id = azurerm_application_load_balancer.agc.id
  subnet_id                    = azurerm_subnet.snet_agc.id
}

resource "azurerm_application_load_balancer_frontend" "agc_frontend" {
  name                         = "agc-frontend"
  application_load_balancer_id = azurerm_application_load_balancer.agc.id
}