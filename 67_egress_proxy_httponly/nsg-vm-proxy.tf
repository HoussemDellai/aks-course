# nsg
resource "azurerm_network_security_group" "nsg-vm-proxy" {
  name                = "nsg-vm-proxy"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# nsg rule
resource "azurerm_network_security_rule" "nsg-allow-ssh" {
  name                        = "nsg-allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg-vm-proxy.name
}

resource "azurerm_network_security_rule" "nsg-allow-http" {
  name                        = "nsg-allow-http"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg-vm-proxy.name
}

# attach nsg to NIC
resource "azurerm_network_interface_security_group_association" "nsg-association-vm-proxy" {
  network_interface_id      = azurerm_network_interface.nic-vm-proxy.id
  network_security_group_id = azurerm_network_security_group.nsg-vm-proxy.id
}