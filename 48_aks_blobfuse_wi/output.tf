output "service_account_name" {
  value = var.service_account_name
}

output "service_account_namespace" {
  value = var.service_account_namespace
}

output "storage_account_name" {
  value = var.storage_account_name
}

output "storage_account_rg" {
  value = var.storage_account_rg
}

output "identity_wi_client_id" {
  value = azurerm_user_assigned_identity.identity_wi.client_id
}

output "aks_oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}