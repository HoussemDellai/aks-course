module "azure_ubuntu_vm_k3s_001" {
  source = "./modules/k3s"

  client_id            = var.client_id
  client_secret        = var.client_secret
  tenant_id            = var.tenant_id
  location             = var.location
  azure_resource_group = "rg-arc-k8s-k3s-${var.location}-${var.prefix}-001"
}

output "vm_pip" {
  value = module.azure_ubuntu_vm_k3s_001.vm_pip
}