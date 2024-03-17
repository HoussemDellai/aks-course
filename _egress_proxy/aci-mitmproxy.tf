resource "azurerm_container_group" "aci-mitmproxy" {
  name                = "aci-mitmproxy"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  os_type             = "Linux"

  container {
    name   = "mitmproxy"
    image  = "mitmproxy/mitmproxy:latest"
    cpu    = "1.0"
    memory = "1.0"

    commands = [
      "/bin/bash",
      "-c",
      "mitmweb --listen-port 8080 --web-host 0.0.0.0 --web-port 8081 --set block_global=false"
      # "apt update -y; apt install wget -y; wget 'https://raw.githubusercontent.com/HoussemDellai/docker-kubernetes-course/main/_egress_proxy/certificate/cert.pem'; mitmweb --listen-port 8080 --web-host 0.0.0.0 --web-port 8081 --set block_global=false --certs *=cert.pem"
    ]

    ports {
      port     = 8080
      protocol = "TCP"
    }

    ports {
      port     = 8081
      protocol = "TCP"
    }
  }

  exposed_port = [
    {
      port     = 8080
      protocol = "TCP"
    },
    {
      port     = 8081
      protocol = "TCP"
  }]
}

# resource "terraform_data" "aci-mitmproxy-get-certificate" {
#   triggers_replace = [
#     azurerm_container_group.aci-mitmproxy.id
#   ]

#   provisioner "local-exec" {
#     command = "az container exec -g ${azurerm_container_group.aci-mitmproxy.resource_group_name} --name ${azurerm_container_group.aci-mitmproxy.name} --exec-command 'cat ~/.mitmproxy/mitmproxy-ca-cert.pem | base64'"
#   }
# }

output "aci-mitmproxy-public_ip" {
  value = azurerm_container_group.aci-mitmproxy.ip_address
}
