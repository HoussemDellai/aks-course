resource "azurerm_key_vault" "keyvault" {
  name                          = "kv4aks${var.prefix}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  enabled_for_disk_encryption   = false
  public_network_access_enabled = true
  sku_name                      = "standard"
  enable_rbac_authorization     = true
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_certificate" "aks-ingress-tls-01" {
  name         = "aks-ingress-tls-01"
  key_vault_id = azurerm_key_vault.keyvault.id

  certificate {
    contents = filebase64("../cert/aks-ingress-tls.pfx")
    password = ""
  }

  depends_on = [ azurerm_role_assignment.keyvault-secrets-officer ]
}

resource "azurerm_key_vault_certificate" "aks-ingress-tls-02" {
  name         = "aks-ingress-tls-02"
  key_vault_id = azurerm_key_vault.keyvault.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = [var.custom_domain_name]
      }

      subject            = "CN=${var.custom_domain_name}"
      validity_in_months = 12
    }
  }

  depends_on = [ azurerm_role_assignment.keyvault-secrets-officer ]
}

resource "azurerm_role_assignment" "keyvault-secrets-officer" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}