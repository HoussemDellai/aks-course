resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks"
  kubernetes_version  = "1.29.0"

  network_profile {
    network_plugin      = "azure" # "kubenet"
  }

  default_node_pool {
    name           = "systempool"
    node_count     = 3
    vm_size        = "standard_b2als_v2"
    vnet_subnet_id = azurerm_subnet.snet-aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  http_proxy_config {
    http_proxy  = "http://${azurerm_network_interface.nic-vm-proxy.private_ip_address}:8080/" # "http://${azurerm_container_group.aci-mitmproxy.ip_address}:8080/" # "http://${azurerm_public_ip.pip-vm-proxy.ip_address}:8080/" # "http://${azurerm_container_group.aci-mitmproxy.ip_address}:8080/" # "http://20.76.37.30:8080/"
    https_proxy = "https://${azurerm_network_interface.nic-vm-proxy.private_ip_address}:8080/" # "http://${azurerm_container_group.aci-mitmproxy.ip_address}:8080/" # "https://${azurerm_public_ip.pip-vm-proxy.ip_address}:8080/" # "http://20.76.37.30:8080/"
    no_proxy    = ["localhost", "127.0.0.1", "docker.io", "docker.com"]
    trusted_ca  = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURnekNDQW11Z0F3SUJBZ0lVUzJTOHNMblQ1bi8vNkM3QTErMG01WXJUejhRd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1VURUxNQWtHQTFVRUJoTUNSbEl4RXpBUkJnTlZCQWdNQ2xOdmJXVXRVM1JoZEdVeElUQWZCZ05WQkFvTQpHRWx1ZEdWeWJtVjBJRmRwWkdkcGRITWdVSFI1SUV4MFpERUtNQWdHQTFVRUF3d0JLakFlRncweU5EQXpNVFl3Ck9UUTVNemxhRncweU5EQTBNVFV3T1RRNU16bGFNRkV4Q3pBSkJnTlZCQVlUQWtaU01STXdFUVlEVlFRSURBcFQKYjIxbExWTjBZWFJsTVNFd0h3WURWUVFLREJoSmJuUmxjbTVsZENCWGFXUm5hWFJ6SUZCMGVTQk1kR1F4Q2pBSQpCZ05WQkFNTUFTb3dnZ0VpTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFDWjVsUncvZFVlCkJsNXFjSzZSUUUrM1RwdTV5bWgxZDVDR0RwYkt2RDZ0djUwRjc5Y0JuUDJYODJ4aVJWU2R2TXJYZEx4MWJkek4KMVBnbjY4cVloSHVSOSt6TVdUN2VZUUtMZi9FYm9mSUEzbWhhS0xsVXFnTjNIRTNaMDU0RUdkQ0RrTlB3c3QyUAp6ckdBM3dVeDJyYkhXRzRpcC9SN1MvN0hIamtHdWh4QXFYZEdUM1BZdnBvKzh6RGVVeTdVRUxWYXg5VS9zdUFOCmhOMktweWxUZThLQmNVNnNFclNjUjdxYU8xLzdJYmVFRW9oQXhpblJ5SFQzaHJQZlY3WktjR0Q3NWtZUkJyRUMKWUdVL203bUsyeDJwek4zNmpad012ckxWZ3dkQkFieHpTSkxFSkR2YlVBWmZZalg3Y2w2SDNqL3ozYW1sTVdMbgpvU2NBeStkVTBFVkRBZ01CQUFHalV6QlJNQjBHQTFVZERnUVdCQlN1Y2VBWXQ2NE96Wk1XUXp3Q3BvZWVvRHk4ClVEQWZCZ05WSFNNRUdEQVdnQlN1Y2VBWXQ2NE96Wk1XUXp3Q3BvZWVvRHk4VURBUEJnTlZIUk1CQWY4RUJUQUQKQVFIL01BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQkswdFdybDZ3b1dDUCs1bS81VWx4SWl3MnE2d1QvdVQwVgpCR2J5QllYTGZKcms5L1lXQVBZR05yaFdmekhVQU8vaEIrbVY5TDU2UlU3NHAvYk51MXdqdGZuT0phRjl5YmUwCmhyMFNsaDlkdFdvRnBHeFVzMGlFVVFHNmhEVzM5bDg2TTlweVJ6NFYrWjVGVHMvMEkya2NTUk1ySk9PZk5JZm4KMkJiVSs4Z1FUV0U5L3gvcThOcWJocUZxSUQybkZXWjl4aUlvWG1GSmt5T3hNeU1ZS2RyTERERUlHa2ZEWHhqNQphUHp1Y3l4S0ZBVzNtbWEwd1Y3WEZFdE8yYjVDMkh1YjdEN2RlbDBkSzFmZUsveWR6Z2szaTdIREFvaFZKSFlLCmZxVzVZWlpNMjkyLzY1VThPaWJmNmtjYTNZOGRFTFRPYzkxRUdPdkt2SVBJQVQvdTFFTmgKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
  }

  lifecycle {
    ignore_changes = [
      default_node_pool.0.upgrade_settings,
      http_proxy_config.0.no_proxy
    ]
  }
}

resource "terraform_data" "aks-get-credentials" {
  triggers_replace = [
    azurerm_kubernetes_cluster.aks.id
  ]

  provisioner "local-exec" {
    command = "az aks get-credentials -g ${azurerm_kubernetes_cluster.aks.resource_group_name} -n ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing"
  }
}
