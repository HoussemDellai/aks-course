resource "azurerm_mssql_server" "mssql-server" {
  name                          = "mssql-server-67-dev"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "12.0"
  administrator_login           = "azureuser"
  administrator_login_password  = "@Aa123456789"
  public_network_access_enabled = true
}

resource "azurerm_mssql_database" "database" {
  name           = "ProductsDB"
  server_id      = azurerm_mssql_server.mssql-server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  read_scale     = false
  sku_name       = "Basic" # GP_S_Gen5_2,HS_Gen4_1,BC_Gen5_2, ElasticPool, Basic,S0, P2 ,DW100c, DS100
  zone_redundant = false
}

# works when public_network_access_enabled = true
resource "azurerm_mssql_firewall_rule" "rule-aks-lb" {
  name             = "rule-aks-lb"
  server_id        = azurerm_mssql_server.mssql-server.id
  start_ip_address = data.azurerm_public_ip.pip-loadbalancer-aks.ip_address
  end_ip_address   = data.azurerm_public_ip.pip-loadbalancer-aks.ip_address
}

resource "azurerm_mssql_firewall_rule" "rule-current-machine" {
  name             = "rule-current-machine"
  server_id        = azurerm_mssql_server.mssql-server.id
  start_ip_address = local.machine_ip
  end_ip_address   = local.machine_ip
}

data "http" "machine_ip" {
  url = "http://ifconf.me"

  request_headers = {
    Accept = "application/json"
  }
}

locals {
  machine_ip = replace(data.http.machine_ip.response_body, "\n", "")
  aks_lb_ip  = split("/", tolist(azurerm_kubernetes_cluster.aks.network_profile.0.load_balancer_profile.0.effective_outbound_ips)[0])[8]
}

data "azurerm_public_ip" "pip-loadbalancer-aks" {
  name                = local.aks_lb_ip
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "mssql_server_fqdn" {
  value = azurerm_mssql_server.mssql-server.fully_qualified_domain_name
}

output "sqlcmd" {
  value     = "sqlcmd -S ${azurerm_mssql_server.mssql-server.fully_qualified_domain_name} -U ${azurerm_mssql_server.mssql-server.administrator_login} -P @Aa123456789 -d ${azurerm_mssql_database.database.name} -Q 'select @@version'"
  sensitive = false
}
