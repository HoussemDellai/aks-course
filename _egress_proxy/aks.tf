resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks"
  kubernetes_version  = "1.29.0"

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    ebpf_data_plane     = "cilium"
    outbound_type       = "loadBalancer"
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
    http_proxy  = "http://${azurerm_public_ip.pip-vm-proxy.ip_address}:8080/" # "http://${azurerm_network_interface.nic-vm-proxy.private_ip_address}:8080/"  # "http://${azurerm_public_ip.pip-vm-proxy.ip_address}:8080/" # "http://${azurerm_container_group.aci-mitmproxy.ip_address}:8080/" # "http://20.76.37.30:8080/"
    https_proxy = "https://${azurerm_public_ip.pip-vm-proxy.ip_address}:8080/" # "https://${azurerm_network_interface.nic-vm-proxy.private_ip_address}:8080/" # "http://20.76.37.30:8080/"
    no_proxy    = ["localhost", "127.0.0.1", "docker.io"]                                      #, azurerm_subnet.snet-aks.address_prefixes[0]]
    trusted_ca  = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUQwekNDQXJ1Z0F3SUJBZ0lVRmc5N0RxL2tEYUNjQTgvcy83NnRuWUZjTENrd0RRWUpLb1pJaHZjTkFRRUwKQlFBd2VURUxNQWtHQTFVRUJoTUNSbEl4RGpBTUJnTlZCQWdNQlZCaGNtbHpNUTR3REFZRFZRUUhEQVZRWVhKcApjekVOTUFzR0ExVUVDZ3dFWTI5eWNERVBNQTBHQTFVRUN3d0dkVzdEZ3pBeE1Rb3dDQVlEVlFRRERBRXFNUjR3CkhBWUpLb1pJaHZjTkFRa0JGZzlsYldGcGJFQmxiV0ZwYkM1amIyMHdIaGNOTWpRd016RTNNRFl6TkRFMFdoY04KTWpRd05ERTJNRFl6TkRFMFdqQjVNUXN3Q1FZRFZRUUdFd0pHVWpFT01Bd0dBMVVFQ0F3RlVHRnlhWE14RGpBTQpCZ05WQkFjTUJWQmhjbWx6TVEwd0N3WURWUVFLREFSamIzSndNUTh3RFFZRFZRUUxEQVoxYnNPRE1ERXhDakFJCkJnTlZCQU1NQVNveEhqQWNCZ2txaGtpRzl3MEJDUUVXRDJWdFlXbHNRR1Z0WVdsc0xtTnZiVENDQVNJd0RRWUoKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTWI4aEc3UlcvNGxqeUZaZ2dBM1A0YStjTHE3YmtJTAp3ZWNwbGsyZkx1M1dGSFhxdjZMS0Z1TXdWWVI2S0lScjNiVldRb0RUQ1FLN25sMVB2d2lhR2ozMGZqc1QzRmI4CkV4ZzdzdCtFSFMzWVJibm53WHB5N25wOHFSRUYwU0puQXhKMmV2V2tKQk1jSEJFTCtuU2ZMclJxSnAvVU52N0IKYzhtVlYyb29JTkZXZGNZSElaQ3JMUEMyc3NnSW42K2lLQkZmbDBPYVdZUkZPMUdRRkg2N0s0NC9jVnlVRVFQTApaYTlXNy92bzlqOVY1QThvaXFXa2F4OTdPTHN5TzVSQlJCV0kwVmZCRzUxT0FXVld2N3BqWU50NUlSNW5XelBnCkpiS1FNL0w2d0pOWlBNbVF1YUdlSVA1MkFZSjJDQk9mL3FyaVFMOHNUSjY0WEVoNGcreHNLRXNDQXdFQUFhTlQKTUZFd0hRWURWUjBPQkJZRUZPa1pMMEhmSzRmT1FkMlJUZURDUTBaVFUvYUJNQjhHQTFVZEl3UVlNQmFBRk9rWgpMMEhmSzRmT1FkMlJUZURDUTBaVFUvYUJNQThHQTFVZEV3RUIvd1FGTUFNQkFmOHdEUVlKS29aSWh2Y05BUUVMCkJRQURnZ0VCQUkwR2VwOEo5YXlQbmxiUm5XSFFRcE45NHhVdVNuU3kwaEVGYlNzeXlBNE5RRmhVcDNjZU5ES1AKZjRCMW1zNnAwVnRNWmhiTDhaOUJmVmlsQ1B0TnhVc0p4OEVvdGdWSE9Ncm1abTlKei9SK0pnRHBQZlhTYUNoQgorZlhucUJROUZqaXU4SUlXMkxKTTJ3ZVRXMnBoWnFsMUpBT1JsRDcwTnlKdXlOVk9ScWc3aUp4SjhGZHI5KzNnClF4TlllNE5pcnFnSzh5dzErQU4xR1hCeklLV0dVT25jRlIzUWhaSWlXMHBQOEx5cjFoODZNV3gxQ0xIb3daT0YKTjZscFpZK0Rpa0o2bGFHK0JLSGZwOFJjVFdrclM3V3pZYldScHVjTlZKZlliZ1VwaVhMcGlQSjR6VjZhM1UyeQpwcTgva29WMS9KQ2tQeEN0UEw0RnhYeVhPWUdqb0dZPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
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
