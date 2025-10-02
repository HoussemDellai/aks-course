module "azure_ubuntu_vm_k3s_001" {
  source = "./modules/k3s"

  client_id            = var.client_id
  client_secret        = var.client_secret
  tenant_id            = var.tenant_id
  location             = var.location
  azure_resource_group = "rg-arc-k8s-k3s-${var.location}-${var.prefix}-001"
}

module "azure_ubuntu_vm_k3s_002" {
  source = "./modules/k3s"

  client_id            = var.client_id
  client_secret        = var.client_secret
  tenant_id            = var.tenant_id
  location             = var.location
  azure_resource_group = "rg-arc-k8s-k3s-${var.location}-${var.prefix}-002"
}

output "azure_ubuntu_vm_k3s_pip_001" {
  value = module.azure_ubuntu_vm_k3s_001.vm_pip
}

output "azure_ubuntu_vm_k3s_pip_002" {
  value = module.azure_ubuntu_vm_k3s_002.vm_pip
}