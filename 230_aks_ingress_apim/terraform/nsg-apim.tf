resource "azurerm_network_security_group" "nsg-apim" {
  name                = "nsg-apim"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet_network_security_group_association" "nsg-association" {
  subnet_id                 = azurerm_subnet.snet-apim.id
  network_security_group_id = azurerm_network_security_group.nsg-apim.id
}

resource "azurerm_network_security_rule" "allow-inbound-infra-lb" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg-apim.name
  name                        = "allow-inbound-infra-lb"
  access                      = "Allow"
  priority                    = 1000 # between 100 and 4096, must be unique, The lower the priority number, the higher the priority of the rule.
  direction                   = "Inbound"
  protocol                    = "Tcp"               # Tcp, Udp, Icmp, Esp, Ah or * (which matches all).
  source_address_prefix       = "AzureLoadBalancer" # CIDR or source IP range or * to match any IP, Supports Tags like VirtualNetwork, AzureLoadBalancer and Internet.
  source_port_range           = "*"                 # between 0 and 65535 or * to match any
  destination_address_prefix  = "VirtualNetwork"
  destination_port_range      = "6390"
}

resource "azurerm_network_security_rule" "allow-inbound-apim" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg-apim.name
  name                        = "allow-inbound-apim"
  access                      = "Allow"
  priority                    = 1010 # between 100 and 4096, must be unique, The lower the priority number, the higher the priority of the rule.
  direction                   = "Inbound"
  protocol                    = "Tcp"           # Tcp, Udp, Icmp, Esp, Ah or * (which matches all).
  source_address_prefix       = "ApiManagement" # CIDR or source IP range or * to match any IP, Supports Tags like VirtualNetwork, AzureLoadBalancer and Internet.
  source_port_range           = "*"             # between 0 and 65535 or * to match any
  destination_address_prefix  = "VirtualNetwork"
  destination_port_range      = "3443"
}

resource "azurerm_network_security_rule" "allow-inbound-internet-http" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg-apim.name
  name                        = "allow-inbound-internet-http"
  access                      = "Allow"
  priority                    = 1020 # between 100 and 4096, must be unique, The lower the priority number, the higher the priority of the rule.
  direction                   = "Inbound"
  protocol                    = "Tcp"      # Tcp, Udp, Icmp, Esp, Ah or * (which matches all).
  source_address_prefix       = "Internet" # CIDR or source IP range or * to match any IP, Supports Tags like VirtualNetwork, AzureLoadBalancer and Internet.
  source_port_range           = "*"        # between 0 and 65535 or * to match any
  destination_address_prefix  = "VirtualNetwork"
  destination_port_range      = "80"
}

resource "azurerm_network_security_rule" "allow-inbound-internet-https" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg-apim.name
  name                        = "allow-inbound-internet-https"
  access                      = "Allow"
  priority                    = 1030 # between 100 and 4096, must be unique, The lower the priority number, the higher the priority of the rule.
  direction                   = "Inbound"
  protocol                    = "Tcp"      # Tcp, Udp, Icmp, Esp, Ah or * (which matches all).
  source_address_prefix       = "Internet" # CIDR or source IP range or * to match any IP, Supports Tags like VirtualNetwork, AzureLoadBalancer and Internet.
  source_port_range           = "*"        # between 0 and 65535 or * to match any
  destination_address_prefix  = "VirtualNetwork"
  destination_port_range      = "443"
}

resource "azurerm_network_security_rule" "allow-outbound-storage" {
  count                       = 1 # enable if using Azure Storage
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg-apim.name
  name                        = "allow-outbound-storage"
  access                      = "Allow"
  priority                    = 1020 # between 100 and 4096, must be unique, The lower the priority number, the higher the priority of the rule.
  direction                   = "Outbound"
  protocol                    = "Tcp"            # Tcp, Udp, Icmp, Esp, Ah or * (which matches all).
  source_address_prefix       = "VirtualNetwork" # CIDR or source IP range or * to match any IP, Supports Tags like VirtualNetwork, AzureLoadBalancer and Internet.
  source_port_range           = "*"              # between 0 and 65535 or * to match any
  destination_address_prefix  = "Storage"
  destination_port_range      = "443"
}

resource "azurerm_network_security_rule" "allow-outbound-azuresql" {
  count                       = 1 # enable if using Azure SQL
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg-apim.name
  name                        = "allow-outbound-azure-sql"
  access                      = "Allow"
  priority                    = 1030 # between 100 and 4096, must be unique, The lower the priority number, the higher the priority of the rule.
  direction                   = "Outbound"
  protocol                    = "Tcp"            # Tcp, Udp, Icmp, Esp, Ah or * (which matches all).
  source_address_prefix       = "VirtualNetwork" # CIDR or source IP range or * to match any IP, Supports Tags like VirtualNetwork, AzureLoadBalancer and Internet.
  source_port_range           = "*"              # between 0 and 65535 or * to match any
  destination_address_prefix  = "SQL"
  destination_port_range      = "1443"
}

resource "azurerm_network_security_rule" "allow-outbound-keyvault" {
  count                       = 1 # enable if using Azure Key vault
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg-apim.name
  name                        = "allow-outbound-keyvault"
  access                      = "Allow"
  priority                    = 1040 # between 100 and 4096, must be unique, The lower the priority number, the higher the priority of the rule.
  direction                   = "Outbound"
  protocol                    = "Tcp"            # Tcp, Udp, Icmp, Esp, Ah or * (which matches all).
  source_address_prefix       = "VirtualNetwork" # CIDR or source IP range or * to match any IP, Supports Tags like VirtualNetwork, AzureLoadBalancer and Internet.
  source_port_range           = "*"              # between 0 and 65535 or * to match any
  destination_address_prefix  = "AzureKeyVault"
  destination_port_range      = "443"
}
