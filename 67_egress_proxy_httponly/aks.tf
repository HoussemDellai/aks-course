resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks"
  kubernetes_version  = "1.29.4"

  network_profile {
    network_plugin = "azure" # "kubenet"
  }

  default_node_pool {
    name           = "systempool"
    node_count     = 3
    vm_size        = "standard_b2als_v2"
    vnet_subnet_id = azurerm_subnet.snet-aks.id
    temporary_name_for_rotation = "systempool2"
  }

  identity {
    type = "SystemAssigned"
  }

  http_proxy_config {
    http_proxy  = "http://${azurerm_network_interface.nic-vm-proxy.private_ip_address}:8080/" # "http://${azurerm_public_ip.pip-vm-proxy.ip_address}:8080/" #  # "http://${azurerm_container_group.aci-mitmproxy.ip_address}:8080/" # "http://${azurerm_public_ip.pip-vm-proxy.ip_address}:8080/" # "http://${azurerm_container_group.aci-mitmproxy.ip_address}:8080/" # "http://20.76.37.30:8080/"
    https_proxy = "https://${azurerm_network_interface.nic-vm-proxy.private_ip_address}:8080/" # "https://${azurerm_public_ip.pip-vm-proxy.ip_address}:8080/" #  # "http://${azurerm_container_group.aci-mitmproxy.ip_address}:8080/" # "https://${azurerm_public_ip.pip-vm-proxy.ip_address}:8080/" # "http://20.76.37.30:8080/"
    no_proxy    = ["localhost", "127.0.0.1", "docker.io", "docker.com", "mcr.microsoft.com"]
    trusted_ca  = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tDQpNSUlFQXpDQ0F1dWdBd0lCQWdJVUdIZ3hRYU1jUlJhVzJ0enpNR3RMRmJpM1Y3OHdEUVlKS29aSWh2Y05BUUVMDQpCUUF3Z1pBeEN6QUpCZ05WQkFZVEFrWlNNUTR3REFZRFZRUUlEQVZRWVhKcGN6RU9NQXdHQTFVRUJ3d0ZVR0Z5DQphWE14RWpBUUJnTlZCQW9NQ1UxcFkzSnZjMjltZERFTU1Bb0dBMVVFQ3d3RFExTlZNUmN3RlFZRFZRUUREQTVJDQpiM1Z6YzJWdElFUmxiR3hoYVRFbU1DUUdDU3FHU0liM0RRRUpBUllYYUc5MWMzTmxiUzVrWld4c1lXbEFiR2wyDQpaUzVqYjIwd0hoY05NalF3TlRJME1UQXpNalUzV2hjTk1qUXdOakl6TVRBek1qVTNXakNCa0RFTE1Ba0dBMVVFDQpCaE1DUmxJeERqQU1CZ05WQkFnTUJWQmhjbWx6TVE0d0RBWURWUVFIREFWUVlYSnBjekVTTUJBR0ExVUVDZ3dKDQpUV2xqY205emIyWjBNUXd3Q2dZRFZRUUxEQU5EVTFVeEZ6QVZCZ05WQkFNTURraHZkWE56WlcwZ1JHVnNiR0ZwDQpNU1l3SkFZSktvWklodmNOQVFrQkZoZG9iM1Z6YzJWdExtUmxiR3hoYVVCc2FYWmxMbU52YlRDQ0FTSXdEUVlKDQpLb1pJaHZjTkFRRUJCUUFEZ2dFUEFEQ0NBUW9DZ2dFQkFOUDY1RHVsSlNESlNyZFBTQWoyT2RmOHBNdVBWbXdXDQoxaC84UUZKRk5iSUdwU200bkdJbHlMUzNoQ2NYYTRVOTZUVWRCUnNnZENWWmdsWTJ6MUJGWHdKV1IrME1ZWGx5DQpTSTZlaFpyZno1Q3ZGL0FRRkxsZHp6K3VKZTY4MWdOS0QwaVJJRjRHd0hGL3RnbUw1QXduemVFeVFzY2lRWnFwDQowSy9vb215UCtSSDFnWSswVjM4OFMvV1lwVEhYZDJhSW1pdUZKeWdnd0xHbEFlYjNDVzlGOURHRWVPK0NMdks2DQppMlNSL25PSFZCYWVHSnJ6MG9OUmx0VmtpcldyMmNzbmd1cUt5Q2VEVFZvZDBUMHlMSmJuNjkzZktrM1hnUmhMDQpHOTNJMXRTdCtZMklWeUxuK2ovaWpwYlVOYVNHQmdRdGx3L2VSdG4vbGk2VGE3U3BYNWV1bHNjQ0F3RUFBYU5UDQpNRkV3SFFZRFZSME9CQllFRk9OYk80WmVOYTBZWGMwWlFDOGJZRDhxaFpad01COEdBMVVkSXdRWU1CYUFGT05iDQpPNFplTmEwWVhjMFpRQzhiWUQ4cWhaWndNQThHQTFVZEV3RUIvd1FGTUFNQkFmOHdEUVlKS29aSWh2Y05BUUVMDQpCUUFEZ2dFQkFLbjl6ZEZjUEs0dCt6eEpLRG1rTTBaWnhXbjhyTE1hUmVzNFZ2Q0dFYjNzSWNQSmpGaVN2aTBkDQp1YU4xdzFXSDV0MXlsRmFLTEdjOTN6c2FIVVlMd3YzWGM4Y1FXU2dIWjhMWVZ6RG0zdTFxc2E0NzlqajlhMmE3DQpwaVpDUHRqRlBTVFJnYW41bllIV1lZN2ZvTVZ4VzNOSWp2MjdpTksrVnBRdzAxMzNIbG9XblFSNmpRcGJvMHAzDQpFL2NMSGZoZkU2UUJNck91d2lraEVMNmI4eE9LdXZFS3haREpBdWlQS2EvUkhUTFZ3a2RuRWUxcUxWTW5EaHgvDQpaZURKWlNNaGVQL3RUQ3Q5dlZlRmh4WTBnQnRrYzRBUUpxc1ZMaWlIWi9FbzdIZDBEaTFNK1lEZm1VNVhLQnQvDQpjTWFXMEJkMWVzdFJVdWI2cnZEa0VWQ2tDSWFTMGJJPQ0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQ0K"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool.0.upgrade_settings,
      http_proxy_config.0.no_proxy
    ]
  }
}

resource "terraform_data" "aks-get-credentials" {
  triggers_replace = [azurerm_kubernetes_cluster.aks.id]

  provisioner "local-exec" {
    command = "az aks get-credentials -n ${azurerm_kubernetes_cluster.aks.name} -g ${azurerm_kubernetes_cluster.aks.resource_group_name} --overwrite-existing"
  }
}