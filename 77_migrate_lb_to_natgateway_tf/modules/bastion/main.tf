resource "azurerm_public_ip" "pip" {
  name                = "pip-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                   = "bastion-host"
  location               = var.location
  resource_group_name    = var.resource_group_name
  sku                    = "Basic" # "Standard" # Developer
  copy_paste_enabled     = true
  file_copy_enabled      = false
  shareable_link_enabled = false
  tunneling_enabled      = false
  ip_connect_enabled     = false

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}
