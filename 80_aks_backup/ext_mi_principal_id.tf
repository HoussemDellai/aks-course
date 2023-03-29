###################################################################
# Get the Managed Identity for AKS backup extension (not working)
# bug in data azurerm_resources: not retrieving all requested MIs !!!
###################################################################

# data azurerm_resources mi_ext_aks_01 {
#   type = "Microsoft.ManagedIdentity/userAssignedIdentities"
#   resource_group_name = azurerm_kubernetes_cluster.aks_01.node_resource_group
# }

# locals {
#   mi_ext_principal_id_aks_01 = [
#     for mi in data.azurerm_resources.mi_ext_aks_01.resources : 
#       mi.id
#       # if startswith(mi.id, "ext-")
#       # && endswith (mi.id, "-aks-01")
#   ]
#   # mi_ext_principal_id_aks_01 = element([
#   #   for mi in data.azurerm_resources.mi_ext_aks_01.resources : 
#   #     mi.id
#   #     if startswith(mi.id, "ext-")
#   #     && endswith (mi.id, "-aks-01")
#   # ], 1)
# }

# output "mi_ext_principal_id_aks_01" {
#   value = local.mi_ext_principal_id_aks_01
# }

# output "data_mi_ext_aks_01" {
#   value = data.azurerm_resources.mi_ext_aks_01
# }

###################################################################
# Get the Managed Identity for AKS backup extension (another solution)
###################################################################

data "azurerm_resources" "vmss_aks_01" {
  type                = "Microsoft.Compute/virtualMachineScaleSets"
  resource_group_name = azurerm_kubernetes_cluster.aks_01.node_resource_group
}

locals {
  vmss_aks_01_ids = [
    for vmss in data.azurerm_resources.vmss_aks_01.resources :
    vmss.id
    if startswith(vmss.name, "aks-")
    && endswith(vmss.name, "-vmss")
  ]
}

data "azurerm_virtual_machine_scale_set" "vmss_aks_01" {
  name                = split("/", local.vmss_aks_01_ids[0])[8]
  resource_group_name = split("/", local.vmss_aks_01_ids[0])[4]
}

locals {
  mi_ext_principal_id_aks_01 = element([
    for mi_id in data.azurerm_virtual_machine_scale_set.vmss_aks_01.identity.0.identity_ids :
    mi_id
    if endswith(mi_id, azurerm_kubernetes_cluster.aks_01.name) # "-aks-01"
    && startswith(split("/", mi_id)[8], "ext-")
  ], 1)
}

data "azurerm_user_assigned_identity" "mi_ext_aks_01" {
  name                = split("/", local.mi_ext_principal_id_aks_01)[8]
  resource_group_name = split("/", local.mi_ext_principal_id_aks_01)[4]
}

output "mi_ext_aks_01_principal_id" {
  value = data.azurerm_user_assigned_identity.mi_ext_aks_01.principal_id
}


###################################################################
# Get the Managed Identity for AKS backup extension for aks-02
###################################################################

data "azurerm_resources" "vmss_aks_02" {
  type                = "Microsoft.Compute/virtualMachineScaleSets"
  resource_group_name = azurerm_kubernetes_cluster.aks_02.node_resource_group
}

locals {
  vmss_aks_02_ids = [
    for vmss in data.azurerm_resources.vmss_aks_02.resources :
    vmss.id
    if startswith(vmss.name, "aks-")
    && endswith(vmss.name, "-vmss")
  ]
}

data "azurerm_virtual_machine_scale_set" "vmss_aks_02" {
  name                = split("/", local.vmss_aks_02_ids[0])[8]
  resource_group_name = split("/", local.vmss_aks_02_ids[0])[4]
}

locals {
  mi_ext_principal_id_aks_02 = element([
    for mi_id in data.azurerm_virtual_machine_scale_set.vmss_aks_02.identity.0.identity_ids :
    mi_id
    if endswith(mi_id, azurerm_kubernetes_cluster.aks_02.name) # "-aks-02"
    && startswith(split("/", mi_id)[8], "ext-")
  ], 1)
}

data "azurerm_user_assigned_identity" "mi_ext_aks_02" {
  name                = split("/", local.mi_ext_principal_id_aks_02)[8]
  resource_group_name = split("/", local.mi_ext_principal_id_aks_02)[4]
}

output "mi_ext_aks_02_principal_id" {
  value = data.azurerm_user_assigned_identity.mi_ext_aks_02.principal_id
}