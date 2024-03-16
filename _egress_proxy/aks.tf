# resource "azurerm_kubernetes_cluster" "aks" {
#   name                = "aks-cluster1"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   dns_prefix          = "aks"
#   kubernetes_version  = "1.29.0"

#   network_profile {
#     network_plugin      = "azure"
#     network_plugin_mode = "overlay"
#     ebpf_data_plane     = "cilium"
#     outbound_type       = "loadBalancer"
#   }

#   default_node_pool {
#     name           = "systempool"
#     node_count     = 3
#     vm_size        = "standard_b2als_v2"
#     vnet_subnet_id = azurerm_subnet.snet-aks.id
#   }

#   identity {
#     type = "SystemAssigned"
#   }

#   http_proxy_config {
#     http_proxy  = "http://${azurerm_network_interface.nic-vm-proxy.private_ip_address}:8080/" # "http://${azurerm_public_ip.pip-vm-proxy.ip_address}:8080/" # "http://${azurerm_container_group.aci-mitmproxy.ip_address}:8080/" # "http://20.76.37.30:8080/"
#     https_proxy = "https://${azurerm_network_interface.nic-vm-proxy.private_ip_address}:8080/" # "http://20.76.37.30:8080/"
#     no_proxy    = ["localhost","127.0.0.1"] #, azurerm_subnet.snet-aks.address_prefixes[0]]
#     trusted_ca  = "LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV1d0lCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktVd2dnU2hBZ0VBQW9JQkFRQ0V0SnluNHUvNEVRSUgKRFNkUDYreUp6eHhjMDRieEJlNEZ4OUpLWGNFR21sWUx5NWx0TXRLMVpJUjJDS25SeXljenlIaG9kSWg4R2Y2WgovT2lrWUpNdGprUVM3UnF2T2h2S0RJdmlwdDMyRkx2T1EyS3dnYTFxdUE2K1R6aTEzSHZXTXowOTZkc1Rhak1aClF1K0hkQkc2NXNZakxNdlRhdjFFUGREOXowUU1oc0xSREtMc3RZRjNqY3JDMWU5U1J6NG5OSkJnS2hDcENHQkMKeUVEODdUaVRCK2hYb0lMTldkamRhNXc5ckUza3JHSUkraWw5MDRLTy9wR290V0dZWjh6YlRuaGk3TWlnOFE3dApYVjdNd0pMdUZTeEtDajlDQStHeDY0WENYMTU0aklFNVVxNm4rL2gzZUtBa2owOG9mWTNuRVVNeHpENU90QldsCndac2NnVkNGQWdNQkFBRUNnZjhJanU5RHhkSXAwOUJBM0h3azRSOEdoc0x6NTdCb1d1S0JiWkpEbXMxazJuL2cKTTRFNVAyZHcvbzBidmJYWjJZVlVHOW1vRmhsUTNWeE9IRWFJZkV1UStRbnEzS0pLQWIrYStOMGhINXk3TlVRUQpYZEpvZ0ZyZlpjY1N3WDd6bDd6cDdTRjVMQlFiUTNqNHpuNnpmYUpwcGpYZWVtUFR2QjkxZDlrS1IrcTN1d3BiCktScndLeDd5aHkrYU56UmpsWFdnSzN6TFppRmIzUEw4cGpFV3AyQTlXRTgwdFFHa214YUV0TnJyWHUwYUJpOTUKSlhYQy83dDdnT3B2QWtNamRCaUVseHJGRXoySnIzTGh5UmE4L3hSR0YwQ1pMeGI5VVp3WjAyZHBlQzI2WURmTwpHVmduaTNXT1BwSzdpb1ozMnNrek1uNEhvL3FITHlra0VXcS8zRkVDZ1lFQXUzMWZzL1BnVERYanVwbTIwbkF4Ck92UU5MbDRrSWJ1M2RIeGVrMUw0S2pVUzNLUXV5aGc5ellmNDlMUHphYUt6eUd6SlQ0c2pYKzdMNmNTaWVHUkQKOUp0WWFqcElXVGZDTlZpejNmTDBGTWRxYitBQUlPNk5idHoxaVczMGV4Q25GbnpJeUtHeDNQQkNTaExObjZicwpjKzFEc0FvUkNrWnRUNzZLYWNkZ1NwVUNnWUVBdFRKNk5Zcit4enNEVXlOY0dKL21idmtFY2ppQStWbW1GQmNSCmVLdVRuSUJkdVlIaGUzV0FXZ20yRExNSHVxb0NhZVNUUTBNdDB1ZVdZc2RSSnh6eWVHYnhOYkorSWYyanFUNksKQTZrdlRjVWlwODNNbHNCOWIrUVIrZUlXWDFYK3dNZHdlbHhjTVRyZUlIZEF0Z2VKdi9pRGEvaU10YTZiNnpGYQpSTUR1WWpFQ2dZRUF1YVoxbzN6ek5zT04wZkh2WkFVUDJtNWF0dlVsRmZvSXVHR0dUSjgxZUtYQkhaVzlkd1AxCi9wU0xZZExtVGsxN2RCUzBhZjArYy9uREZLRk90Nk9nM284TVIzT2F2QzFJTXdhNFpDZjBwTGFwb0VuUUZzdmcKWkV5TEhTQXhtOEpya1FyU3prZStGU1lhbmJwc3ZZL09SeVJEaUFjUHhIcmtOcmhYMmxJLytOa0NnWUFxeE5CZAp4UUlnS29pOVhmSkdDYkFOYjQraUdqNHZIUDc3YlBwOXZobm9iZEF4a2p1VHRZZG5PVFdVUjhuQ1FKQ3pSL1dPCmdkUFdIVDI4OFFqeHIzNTM5dXhtWFV3eVg3ajZvTDFZNGQwOWdST09BaUNSVUx3SzVnMXNLdlpXNkdocVBta0oKS0xYR0ZQd0xNN3E5ZklnQ0hQbUFTYm1FeE1NZXY1WnI5aElPY1FLQmdIdnNoZWVadjduUy8vVnZ6d3N0dnk1dgpTRUFQeDR6QnRkSVRITTE4QlBBRjhXSTdmOFRENFR1dGx3cTdjYVNkREhWY29TZCtLc0xKY1IxU0lKVithcWZoCncxcVdPeUsyenZzOGdwQldQMTI0SDdSdjlEL2FNdWE3RHd5QlBHMTRJTWsySXBNVitOU0NiVnFISnFiSzhrSksKVFFwRm1teXl3UlRzQzJmeFNLeVMKLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLQotLS0tLUJFR0lOIENFUlRJRklDQVRFLS0tLS0KTUlJRGF6Q0NBbE9nQXdJQkFnSVVXYUkvTXh3MzkydjJETjh0SUwwL21wZG1UWFF3RFFZSktvWklodmNOQVFFTApCUUF3UlRFTE1Ba0dBMVVFQmhNQ1JsSXhFekFSQmdOVkJBZ01DbE52YldVdFUzUmhkR1V4SVRBZkJnTlZCQW9NCkdFbHVkR1Z5Ym1WMElGZHBaR2RwZEhNZ1VIUjVJRXgwWkRBZUZ3MHlOREF6TVRVeE1qVTJNalJhRncweU5EQTAKTVRReE1qVTJNalJhTUVVeEN6QUpCZ05WQkFZVEFrWlNNUk13RVFZRFZRUUlEQXBUYjIxbExWTjBZWFJsTVNFdwpId1lEVlFRS0RCaEpiblJsY201bGRDQlhhV1JuYVhSeklGQjBlU0JNZEdRd2dnRWlNQTBHQ1NxR1NJYjNEUUVCCkFRVUFBNElCRHdBd2dnRUtBb0lCQVFDRXRKeW40dS80RVFJSERTZFA2K3lKenh4YzA0YnhCZTRGeDlKS1hjRUcKbWxZTHk1bHRNdEsxWklSMkNLblJ5eWN6eUhob2RJaDhHZjZaL09pa1lKTXRqa1FTN1Jxdk9odktESXZpcHQzMgpGTHZPUTJLd2dhMXF1QTYrVHppMTNIdldNejA5NmRzVGFqTVpRdStIZEJHNjVzWWpMTXZUYXYxRVBkRDl6MFFNCmhzTFJES0xzdFlGM2pjckMxZTlTUno0bk5KQmdLaENwQ0dCQ3lFRDg3VGlUQitoWG9JTE5XZGpkYTV3OXJFM2sKckdJSStpbDkwNEtPL3BHb3RXR1laOHpiVG5oaTdNaWc4UTd0WFY3TXdKTHVGU3hLQ2o5Q0ErR3g2NFhDWDE1NApqSUU1VXE2bisvaDNlS0FrajA4b2ZZM25FVU14ekQ1T3RCV2x3WnNjZ1ZDRkFnTUJBQUdqVXpCUk1CMEdBMVVkCkRnUVdCQlI5SEpubmFoQ0xVbjR4ci9rNGdYT0tKZmR0TXpBZkJnTlZIU01FR0RBV2dCUjlISm5uYWhDTFVuNHgKci9rNGdYT0tKZmR0TXpBUEJnTlZIUk1CQWY4RUJUQURBUUgvTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFBZQpPV0tTblpnRFhFVEhsdnV5cWFxbUgyUWNuL1dHcStkaHpRamM0dlJINUZBNm5EcFB0QzYrQnZsVys1L3dwclhmCmhnMEhGZW1nWWpUanJ0UERVemFCUi9aM2hMQ2trMGdZOWNLbGs5K2UyWWhPWnF2TGEvMlhGbkUvRTVEWkV1d0YKTHR3R3o5UFF6QjVPL1E4UGllQnNNb2Nya0xOWXBlbTRrMjFBZU9rWC9FVWdsbmVQYjROM2xWdVd1ejZlaHpKQQoxdjVuUFpHQVRVOWpYTnN6WXRMdGcwZlhhWlkxbk45RVVDTUNRMTVsTVJKY1dsMTNNeHhLN3VlS0pWd2VJTUp6ClR6c0J6cVYyRzh0U09pNlBxNjc4NE05LzRuUUVPbU5GYmlKRDQyVm5GcjFLdysvUmFKcHpEcmFZM0NPVDFQQ3oKV2hmclJNY3NORUQrQkxwMEN5OEUKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
#   }

#   # http_proxy_config {
#   #   http_proxy  = "http://${azurerm_container_group.aci-mitmproxy.ip_address}:8080/"
#   #   https_proxy = "https://${azurerm_container_group.aci-mitmproxy.ip_address}:8080/"
#   #   no_proxy = ["localhost", "127.0.0.1"] #, azurerm_subnet.snet-aks.address_prefixes[0]]
#   #   trusted_ca = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUROVENDQWgyZ0F3SUJBZ0lVR0greHNoSzVYOUZaMDR1WVk0WWZSU0tTdS93d0RRWUpLb1pJaHZjTkFRRUwKQlFBd0tERVNNQkFHQTFVRUF3d0piV2wwYlhCeWIzaDVNUkl3RUFZRFZRUUtEQWx0YVhSdGNISnZlSGt3SGhjTgpNalF3TXpFeU1UWXlPVEkxV2hjTk16UXdNekV5TVRZeU9USTFXakFvTVJJd0VBWURWUVFEREFsdGFYUnRjSEp2CmVIa3hFakFRQmdOVkJBb01DVzFwZEcxd2NtOTRlVENDQVNJd0RRWUpLb1pJaHZjTkFRRUJCUUFEZ2dFUEFEQ0MKQVFvQ2dnRUJBS2hwUE0xMHJ5aGFWQzVDVllNeDdETFlEV2Y2TTcvSDVkQXdmWFlEQ0JWbm4zOFhFbVV6ZGp3NApKRzhjczRJRHBPUFlBY2pCazBscVpWZWd5UkYraDByNk5zcjQ1NENTejRqb2YvcWJKTHAwSkhDWEhmTCtNbDFPCkNEL3ZBcHVoTHRSYlIvdXp1cVU5MnJWOWpNMUExVDRyaVhVQ0xMcmNHMVFOakhMcVRGSkxwR3l3NDdnOGxXUlYKVGcwSkpzK0ZFYXZibjBEQ3JvVDFpem1ZMmNYendQY3JDZHpDbUxpWVR0cVJYaldqZ2NtSWtuWEt6ZlIxVnJ4Vwo1WFNidTVyMExCRzYwQzZxeEtQZlNqQ3EvQm5sTjVMNW8xRlBOekR4NEVCelJvbks4VjA4ZzhqNlRqQUpTakxJClN6VVRYUjMrV1cxR2FHRTdvcmJ0OHdwNGYvbzBPSGtDQXdFQUFhTlhNRlV3RHdZRFZSMFRBUUgvQkFVd0F3RUIKL3pBVEJnTlZIU1VFRERBS0JnZ3JCZ0VGQlFjREFUQU9CZ05WSFE4QkFmOEVCQU1DQVFZd0hRWURWUjBPQkJZRQpGS3c5akdTVS95dlV3cTllaURuSnZ6eXJVOXpFTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFDTUJIU3U0QmlLCkhsdzlzbkV6ejQrTXl2RzdUVzBmdXRyNE5SZ0RyOTZieVBtRXlkWFlLUE85ZlVkQUI2S1J5QTlYWlNMQW4vWlUKWWFsSHlIMzU0NHY3WG1MRG11ZjhPWm8vMjdXdm9WVytGYWFxWnoybldsR1NsbW5XMTZ3SlpMUUpCSSs0U0NsRApTMmxkTnhmOHJFMDh1K2xNY0ZvZmphRG1TbERLNHQ2RXovQ3RmdEcxTWtUUk81N0JhbDlCY0t5RjIzV3ljRXVyCjFHVWt0N29JYWJHaXpkSW84RXFzbnNJSnJyTTRUS1A0NFVMei9aczlpQzUvWUVCUVNrZTg4T3RTc21TQjM5NHIKMEltU2dDOFVJMFB1UzF1YTI2MnNtMUI1dE11Yml6bUVFY3lTQ1pEUDRYTWhCdjBzSU10eldNaGFDazVNY3FvZAoxVXd4ZjRYSEEyU3kKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
#   # }

#   # oms_agent {
#   #   log_analytics_workspace_id      = azurerm_log_analytics_workspace.workspace.id
#   #   msi_auth_for_monitoring_enabled = true
#   # }

#   # monitor_metrics {
#   #   annotations_allowed = null
#   #   labels_allowed      = null
#   # }

#   lifecycle {
#     ignore_changes = [
#       default_node_pool.0.upgrade_settings,
#       http_proxy_config.0.no_proxy
#     ]
#   }
# }

# resource "terraform_data" "aks-get-credentials" {
#   triggers_replace = [
#     azurerm_kubernetes_cluster.aks.id
#   ]

#   provisioner "local-exec" {
#     command = "az aks get-credentials --resource-group ${azurerm_kubernetes_cluster.aks.resource_group_name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing"
#   }
# }
