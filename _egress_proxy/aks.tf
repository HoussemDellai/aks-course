resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster129"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks"
  kubernetes_version  = "1.28.5" # "1.29.0"

  network_profile {
    network_plugin      = "azure" # "kubenet"
    # network_plugin_mode = "overlay"
    # ebpf_data_plane     = "cilium"
    # outbound_type       = "loadBalancer"
    # pod_cidr            = "10.20.0.0/20"
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
    http_proxy  = "http://${azurerm_public_ip.pip-vm-proxy.ip_address}:8080/"  # "http://${azurerm_network_interface.nic-vm-proxy.private_ip_address}:8080/"  # "http://${azurerm_public_ip.pip-vm-proxy.ip_address}:8080/" # "http://${azurerm_container_group.aci-mitmproxy.ip_address}:8080/" # "http://20.76.37.30:8080/"
    https_proxy = "https://${azurerm_public_ip.pip-vm-proxy.ip_address}:8080/" # "https://${azurerm_network_interface.nic-vm-proxy.private_ip_address}:8080/" # "http://20.76.37.30:8080/"
    no_proxy    = ["localhost", "127.0.0.1", "docker.io"]                      #, azurerm_subnet.snet-aks.address_prefixes[0]]
    trusted_ca  = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURnekNDQW11Z0F3SUJBZ0lVUzJTOHNMblQ1bi8vNkM3QTErMG01WXJUejhRd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1VURUxNQWtHQTFVRUJoTUNSbEl4RXpBUkJnTlZCQWdNQ2xOdmJXVXRVM1JoZEdVeElUQWZCZ05WQkFvTQpHRWx1ZEdWeWJtVjBJRmRwWkdkcGRITWdVSFI1SUV4MFpERUtNQWdHQTFVRUF3d0JLakFlRncweU5EQXpNVFl3Ck9UUTVNemxhRncweU5EQTBNVFV3T1RRNU16bGFNRkV4Q3pBSkJnTlZCQVlUQWtaU01STXdFUVlEVlFRSURBcFQKYjIxbExWTjBZWFJsTVNFd0h3WURWUVFLREJoSmJuUmxjbTVsZENCWGFXUm5hWFJ6SUZCMGVTQk1kR1F4Q2pBSQpCZ05WQkFNTUFTb3dnZ0VpTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFDWjVsUncvZFVlCkJsNXFjSzZSUUUrM1RwdTV5bWgxZDVDR0RwYkt2RDZ0djUwRjc5Y0JuUDJYODJ4aVJWU2R2TXJYZEx4MWJkek4KMVBnbjY4cVloSHVSOSt6TVdUN2VZUUtMZi9FYm9mSUEzbWhhS0xsVXFnTjNIRTNaMDU0RUdkQ0RrTlB3c3QyUAp6ckdBM3dVeDJyYkhXRzRpcC9SN1MvN0hIamtHdWh4QXFYZEdUM1BZdnBvKzh6RGVVeTdVRUxWYXg5VS9zdUFOCmhOMktweWxUZThLQmNVNnNFclNjUjdxYU8xLzdJYmVFRW9oQXhpblJ5SFQzaHJQZlY3WktjR0Q3NWtZUkJyRUMKWUdVL203bUsyeDJwek4zNmpad012ckxWZ3dkQkFieHpTSkxFSkR2YlVBWmZZalg3Y2w2SDNqL3ozYW1sTVdMbgpvU2NBeStkVTBFVkRBZ01CQUFHalV6QlJNQjBHQTFVZERnUVdCQlN1Y2VBWXQ2NE96Wk1XUXp3Q3BvZWVvRHk4ClVEQWZCZ05WSFNNRUdEQVdnQlN1Y2VBWXQ2NE96Wk1XUXp3Q3BvZWVvRHk4VURBUEJnTlZIUk1CQWY4RUJUQUQKQVFIL01BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQkswdFdybDZ3b1dDUCs1bS81VWx4SWl3MnE2d1QvdVQwVgpCR2J5QllYTGZKcms5L1lXQVBZR05yaFdmekhVQU8vaEIrbVY5TDU2UlU3NHAvYk51MXdqdGZuT0phRjl5YmUwCmhyMFNsaDlkdFdvRnBHeFVzMGlFVVFHNmhEVzM5bDg2TTlweVJ6NFYrWjVGVHMvMEkya2NTUk1ySk9PZk5JZm4KMkJiVSs4Z1FUV0U5L3gvcThOcWJocUZxSUQybkZXWjl4aUlvWG1GSmt5T3hNeU1ZS2RyTERERUlHa2ZEWHhqNQphUHp1Y3l4S0ZBVzNtbWEwd1Y3WEZFdE8yYjVDMkh1YjdEN2RlbDBkSzFmZUsveWR6Z2szaTdIREFvaFZKSFlLCmZxVzVZWlpNMjkyLzY1VThPaWJmNmtjYTNZOGRFTFRPYzkxRUdPdkt2SVBJQVQvdTFFTmgKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
  }

  # http_proxy_config {
  #   http_proxy  = "http://${azurerm_container_group.aci-mitmproxy.ip_address}:8080/"
  #   https_proxy = "https://${azurerm_container_group.aci-mitmproxy.ip_address}:8080/"
  #   no_proxy = ["localhost", "127.0.0.1"] #, azurerm_subnet.snet-aks.address_prefixes[0]]
  #   trusted_ca = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUROVENDQWgyZ0F3SUJBZ0lVR0greHNoSzVYOUZaMDR1WVk0WWZSU0tTdS93d0RRWUpLb1pJaHZjTkFRRUwKQlFBd0tERVNNQkFHQTFVRUF3d0piV2wwYlhCeWIzaDVNUkl3RUFZRFZRUUtEQWx0YVhSdGNISnZlSGt3SGhjTgpNalF3TXpFeU1UWXlPVEkxV2hjTk16UXdNekV5TVRZeU9USTFXakFvTVJJd0VBWURWUVFEREFsdGFYUnRjSEp2CmVIa3hFakFRQmdOVkJBb01DVzFwZEcxd2NtOTRlVENDQVNJd0RRWUpLb1pJaHZjTkFRRUJCUUFEZ2dFUEFEQ0MKQVFvQ2dnRUJBS2hwUE0xMHJ5aGFWQzVDVllNeDdETFlEV2Y2TTcvSDVkQXdmWFlEQ0JWbm4zOFhFbVV6ZGp3NApKRzhjczRJRHBPUFlBY2pCazBscVpWZWd5UkYraDByNk5zcjQ1NENTejRqb2YvcWJKTHAwSkhDWEhmTCtNbDFPCkNEL3ZBcHVoTHRSYlIvdXp1cVU5MnJWOWpNMUExVDRyaVhVQ0xMcmNHMVFOakhMcVRGSkxwR3l3NDdnOGxXUlYKVGcwSkpzK0ZFYXZibjBEQ3JvVDFpem1ZMmNYendQY3JDZHpDbUxpWVR0cVJYaldqZ2NtSWtuWEt6ZlIxVnJ4Vwo1WFNidTVyMExCRzYwQzZxeEtQZlNqQ3EvQm5sTjVMNW8xRlBOekR4NEVCelJvbks4VjA4ZzhqNlRqQUpTakxJClN6VVRYUjMrV1cxR2FHRTdvcmJ0OHdwNGYvbzBPSGtDQXdFQUFhTlhNRlV3RHdZRFZSMFRBUUgvQkFVd0F3RUIKL3pBVEJnTlZIU1VFRERBS0JnZ3JCZ0VGQlFjREFUQU9CZ05WSFE4QkFmOEVCQU1DQVFZd0hRWURWUjBPQkJZRQpGS3c5akdTVS95dlV3cTllaURuSnZ6eXJVOXpFTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFDTUJIU3U0QmlLCkhsdzlzbkV6ejQrTXl2RzdUVzBmdXRyNE5SZ0RyOTZieVBtRXlkWFlLUE85ZlVkQUI2S1J5QTlYWlNMQW4vWlUKWWFsSHlIMzU0NHY3WG1MRG11ZjhPWm8vMjdXdm9WVytGYWFxWnoybldsR1NsbW5XMTZ3SlpMUUpCSSs0U0NsRApTMmxkTnhmOHJFMDh1K2xNY0ZvZmphRG1TbERLNHQ2RXovQ3RmdEcxTWtUUk81N0JhbDlCY0t5RjIzV3ljRXVyCjFHVWt0N29JYWJHaXpkSW84RXFzbnNJSnJyTTRUS1A0NFVMei9aczlpQzUvWUVCUVNrZTg4T3RTc21TQjM5NHIKMEltU2dDOFVJMFB1UzF1YTI2MnNtMUI1dE11Yml6bUVFY3lTQ1pEUDRYTWhCdjBzSU10eldNaGFDazVNY3FvZAoxVXd4ZjRYSEEyU3kKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
  # }

  # oms_agent {
  #   log_analytics_workspace_id      = azurerm_log_analytics_workspace.workspace.id
  #   msi_auth_for_monitoring_enabled = true
  # }

  # monitor_metrics {
  #   annotations_allowed = null
  #   labels_allowed      = null
  # }

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
    command = "az aks get-credentials --resource-group ${azurerm_kubernetes_cluster.aks.resource_group_name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing"
  }
}
