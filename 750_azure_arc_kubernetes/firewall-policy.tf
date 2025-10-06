resource "azurerm_firewall_policy" "firewall-policy" {
  name                = "firewall-policy"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard" # "Basic" # "Standard" # "Premium" #

  # dns {
  #   proxy_enabled = true
  #   servers       = ["168.63.129.16"]
  # }
}

resource "azurerm_firewall_policy_rule_collection_group" "policy-group-allow" {
  name               = "policy-group-allow"
  firewall_policy_id = azurerm_firewall_policy.firewall-policy.id
  priority           = 1000

  application_rule_collection {
    name     = "allow-all-application-rule"
    priority = 100
    action   = "Allow"

    rule {
      name              = "allow-all"
      source_addresses  = ["*"]
      destination_fqdns = ["*"]
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  network_rule_collection {
    name     = "allow-all-network-rule"
    priority = 500
    action   = "Allow"

    rule {
      name                  = "allow-all"
      protocols             = ["TCP", "UDP", "ICMP", "Any"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
    }
  }
  # rule {
  #   name                  = "allow-spoke1-to-spoke2"
  #   protocols             = ["TCP", "UDP", "ICMP", "Any"]
  #   source_addresses      = azurerm_virtual_network.vnet-spoke1.address_space
  #   destination_addresses = azurerm_virtual_network.vnet-spoke2.address_space
  #   destination_ports     = ["*"]
  # }

  #   rule {
  #     name                  = "allow-spoke2-to-spoke1"
  #     protocols             = ["TCP", "UDP", "ICMP", "Any"]
  #     source_addresses      = azurerm_virtual_network.vnet-spoke2.address_space
  #     destination_addresses = azurerm_virtual_network.vnet-spoke1.address_space
  #     destination_ports     = ["*"]
  #   }
  # }

  # application_rule_collection {
  #   name     = "allow-microsoft.com"
  #   priority = 600
  #   action   = "Allow"

  #   rule {
  #     name              = "allow-microsoft.com"
  #     source_addresses  = azurerm_virtual_network.vnet-spoke1.address_space
  #     destination_fqdns = ["www.microsoft.com"]
  #     protocols {
  #       type = "Http"
  #       port = 80
  #     }
  #     protocols {
  #       type = "Https"
  #       port = 443
  #     }
  #   }
  # }
}
