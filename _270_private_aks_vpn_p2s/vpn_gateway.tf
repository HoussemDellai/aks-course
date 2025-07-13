resource "azurerm_public_ip" "pip-vnet-gateway" {
  name                = "pip-vnet-gateway"
  location            = azurerm_resource_group.rg-hub.location
  resource_group_name = azurerm_resource_group.rg-hub.name

  # for Basic VPN Gateway
  # allocation_method = "Dynamic"
  # sku               = "Basic"

  allocation_method = "Static"
  sku               = "Standard"
  sku_tier          = "Regional"
  zones             = []
}

resource "azurerm_virtual_network_gateway" "vpn-gateway" {
  name                = "vpn-gateway"
  location            = azurerm_resource_group.rg-hub.location
  resource_group_name = azurerm_resource_group.rg-hub.name

  type     = "Vpn"        # ExpressRoute
  vpn_type = "RouteBased" # PolicyBased

  active_active = false
  enable_bgp    = false
  # sku           = "VpnGw2"      # Basic, Standard, HighPerformance, UltraPerformance, Erg-hubw1AZ, Erg-hubw2AZ, Erg-hubw3AZ, VpnGw1, VpnGw2, VpnGw3, VpnGw4,VpnGw5, VpnGw1AZ, VpnGw2AZ, VpnGw3AZ,VpnGw4AZ and VpnGw5AZ
  # generation    = "Generation2" # Generation2 is only value for a sku larg-huber than VpnGw2 or VpnGw2AZ

  sku        = "VpnGw1" # "Basic"
  generation = "Generation1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.pip-vnet-gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.snet-gateway.id
  }

  vpn_client_configuration {
    vpn_client_protocols = ["OpenVPN"] # SSTP, IkeV2 and OpenVPN
    vpn_auth_types       = ["AAD"]     # AAD, Radius and Certificate
    address_space        = ["172.16.0.0/24"]
    aad_audience         = "41b23e61-6c1e-4545-b367-cd054e0ed4b4"
    aad_issuer           = "https://sts.windows.net/${data.azurerm_client_config.current.tenant_id}/"
    aad_tenant           = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}"
  }

  # custom_route {
  #   address_prefixes = ["0.0.0.0/1", "128.0.0.0/1"]
  # }
}

data "azurerm_client_config" "current" {}
