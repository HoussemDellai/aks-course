resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster1"
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
    http_proxy  = "http://${azurerm_container_group.aci-mitmproxy.ip_address}:8080/" # "http://20.76.37.30:8080/"
    https_proxy = "http://${azurerm_container_group.aci-mitmproxy.ip_address}:8080/" # "http://20.76.37.30:8080/"
    no_proxy    = ["localhost","127.0.0.1"] #, azurerm_subnet.snet-aks.address_prefixes[0]]
    trusted_ca  = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUROVENDQWgyZ0F3SUJBZ0lVRmVpUGVORDkweFNtNXlRWVJnT1E1cUplOEdjd0RRWUpLb1pJaHZjTkFRRUwKQlFBd0tERVNNQkFHQTFVRUF3d0piV2wwYlhCeWIzaDVNUkl3RUFZRFZRUUtEQWx0YVhSdGNISnZlSGt3SGhjTgpNalF3TXpFek1EY3pPVFF4V2hjTk16UXdNekV6TURjek9UUXhXakFvTVJJd0VBWURWUVFEREFsdGFYUnRjSEp2CmVIa3hFakFRQmdOVkJBb01DVzFwZEcxd2NtOTRlVENDQVNJd0RRWUpLb1pJaHZjTkFRRUJCUUFEZ2dFUEFEQ0MKQVFvQ2dnRUJBTWJXVnRTKzM5aVd2RFc4bWFVVFhSYi82WlJvN1ZZZ3J2RVpwTFRSOFRIUUpUS3FGT0s0MFVzMgpzL0NZZUVqa2F4WWZFVGZJVGc4YURKVGJGaVpSZElGUklSM1Y5NWJsazV0bVFCb2kzaTVNb0Jhd05sTzgxL0V2CkZRZUZoZlkvdWJja0R4K1ZDRUxNVy9pSEFPUFRpYjRkbE94Y0gxQ3lEVi80TEVnc3JIL2tXN2hJWVo1bXRMblMKcFdHb1FqVlUvVW9tUnNaOXBNb2g1Y1pvbCtlZFNnY1ZlNzdOUiswYWwrdWYzYWpvYnkrcnZZSGdnbjg4bnYrKwpENGpUa01DVUkwMy81KzVxelhaUzR5VDNQbHd1SzA0WEZjMTVDTVJQY3gza3p0ekVYcHIxSDhXMm44QndCMzNiCnYxTnN5WXRGbnNXcFZmVFZKTG5zQWE1NDNTNHZzck1DQXdFQUFhTlhNRlV3RHdZRFZSMFRBUUgvQkFVd0F3RUIKL3pBVEJnTlZIU1VFRERBS0JnZ3JCZ0VGQlFjREFUQU9CZ05WSFE4QkFmOEVCQU1DQVFZd0hRWURWUjBPQkJZRQpGRyt0NGp4NGovWjQyWjNGZW9zdHpOOWk5NFdjTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFDcGZLRlkyRnJOClFoMEo4cENSanE5UGdOekh3N3YzbWpnQTdINXlRWEpDK0VTdmkrMmJiT2NkNTNjdGo1TlpkN3ZjcWVmT3JtRS8KWXNvcElHa0l5dDdqdzV3d1FSNDFDVEhRbjRQTXA5akEySkthWnZqT1I0US9lUGlZSGgxSUozSklUQ25KYVNBRQpIbURTbjVybXlMZlVNSHFKVTdSKzFabDUyNUF4Vk9YeEdDMUZteElTWWhqNG1IcXVwRlBtMm15N3NOYWY2Nm03CjQreW5LZ2ttS3FyS3htZ0pFZk5zK1FPanpGWFlKTzBxczFwNXRJOUszYXF5QnBnVzU5cEJHa0dRMkVLMWduSXMKdlA1K3JjUUV0dTcrcWJGT08yYnByamJlZ1VGbkxuSXlzem5SOHRLdThzWU9vL2pGOFdZNVJsQ1pqQnNvNGxlQgo0MUxLUS9lTU84MjQKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
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
