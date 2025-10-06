locals {
  template_base_url = "https://raw.githubusercontent.com/HoussemDellai/aks-course/refs/heads/main/750_azure_arc_kubernetes/"
  # template_base_url = "https://raw.githubusercontent.com/${var.github_account}/azure_arc/${var.github_branch}/azure_arc_k8s_jumpstart/rancher_k3s/azure/terraform/"
}

resource "azurerm_public_ip" "pip_vm" {
  name                = "pip-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic_vm" {
  name                = "nic-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "private"
    subnet_id                     = azurerm_subnet.snet_vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_vm.id
  }
}

resource "azurerm_linux_virtual_machine" "vm_linux_k3s" {
  name                            = var.vm_name
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_D4ads_v6"
  disable_password_authentication = false
  admin_username                  = "azureuser"
  admin_password                  = "@Aa123456789"
  network_interface_ids           = [azurerm_network_interface.nic_vm.id]
  priority                        = "Spot"
  eviction_policy                 = "Delete"
  disk_controller_type            = "NVMe" # "SCSI" # "IDE" # "SCSI" is the default value. "NVMe" is only supported for Ephemeral OS Disk.

  # custom_data = filebase64("../scripts/install-webapp.sh")

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    name                 = "os-disk"
    caching              = "ReadOnly"        # "ReadWrite" # None, ReadOnly and ReadWrite.
    storage_account_type = "StandardSSD_LRS" # "Standard_LRS"
    disk_size_gb         = 124

    diff_disk_settings {
      option    = "Local"    # Specifies the Ephemeral Disk Settings for the OS Disk. At this time the only possible value is Local.
      placement = "NvmeDisk" # "ResourceDisk" # "CacheDisk" # Specifies the Ephemeral Disk Placement for the OS Disk. NvmeDisk can only be used for v6 VMs
    }
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_role_assignment" "vm_contributor_on_subscription" {
  principal_id         = azurerm_linux_virtual_machine.vm_linux_k3s.identity.0.principal_id
  role_definition_name = "Contributor"
  scope                = data.azurerm_subscription.current.id
}

data "azurerm_subscription" "current" {}