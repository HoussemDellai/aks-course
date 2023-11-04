resource "azurerm_resource_group" "rg-vm" {
  name     = "rg-vm-linux"
  location = "westeurope"
}

resource "azurerm_virtual_network" "vnet-vm" {
  name                = "vnet-vm"
  location            = azurerm_resource_group.rg-vm.location
  resource_group_name = azurerm_resource_group.rg-vm.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet-bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg-vm.name
  virtual_network_name = azurerm_virtual_network.vnet-vm.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "subnet-vm" {
  name                 = "subnet-vm"
  resource_group_name  = azurerm_resource_group.rg-vm.name
  virtual_network_name = azurerm_virtual_network.vnet-vm.name
  address_prefixes     = ["10.0.1.0/24"]
}

module "vm-linux" {
  source              = "./modules/vm_linux"
  vm_name             = "vm-linux"
  resource_group_name = azurerm_resource_group.rg-vm.name
  location            = azurerm_resource_group.rg-vm.location
  subnet_id           = azurerm_subnet.subnet-vm.id
  install_webapp      = true
}

module "bastion" {
  source              = "./modules/bastion"
  resource_group_name = azurerm_resource_group.rg-vm.name
  location            = azurerm_resource_group.rg-vm.location
  subnet_id           = azurerm_subnet.subnet-bastion.id
}

resource "azurerm_virtual_network_peering" "direction1" {
  name                         = "direction1"
  virtual_network_name         = azurerm_virtual_network.vnet-vm.name
  resource_group_name          = azurerm_resource_group.rg-vm.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "vnet_peering_spoke_to_hub" {
  name                         = "direction2"
  virtual_network_name         = azurerm_virtual_network.vnet.name
  resource_group_name          = azurerm_resource_group.rg.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet-vm.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_resource_group" "rg-vm-in" {
  name     = "rg-vm-linux-in"
  location = "westeurope"
}

module "vm-linux-in" {
  source              = "./modules/vm_linux"
  vm_name             = "vm-linux-in"
  resource_group_name = azurerm_resource_group.rg-vm-in.name
  location            = azurerm_resource_group.rg-vm-in.location
  subnet_id           = azurerm_subnet.subnet.id
  install_webapp      = true
}