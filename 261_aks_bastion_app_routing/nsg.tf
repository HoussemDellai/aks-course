resource "azurerm_network_security_group" "nsg-snet-lb" {
  name                = "nsg-snet-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet_network_security_group_association" "nsg-association" {
  subnet_id                 = azurerm_subnet.snet-lb.id
  network_security_group_id = azurerm_network_security_group.nsg-snet-lb.id
}

resource "azurerm_network_security_rule" "allow-inbound-lb" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg-snet-lb.name
  name                        = "allow-inbound-lb"
  access                      = "Deny"
  priority                    = 100 # between 100 and 4096, must be unique, The lower the priority number, the higher the priority of the rule.
  direction                   = "Inbound"
  protocol                    = "*" # Tcp, Udp, Icmp, Esp, Ah or * (which matches all).
  source_address_prefix       = "*"   # CIDR or source IP range or * to match any IP, Supports Tags like VirtualNetwork, AzureLoadBalancer and Internet.
  source_port_range           = "*"   # between 0 and 65535 or * to match any
  destination_address_prefix  = "*"
  destination_port_range      = "*"
}

# deny outbound
resource "azurerm_network_security_rule" "deny-outbound-lb" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg-snet-lb.name
  name                        = "deny-outbound-lb"
  access                      = "Deny"
  priority                    = 100 # between 100 and 4096, must be unique, The lower the priority number, the higher the priority of the rule.
  direction                   = "Outbound"
  protocol                    = "*" # Tcp, Udp, Icmp, Esp, Ah or * (which matches all).
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
}
