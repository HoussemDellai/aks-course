resource "azurerm_data_protection_backup_policy_kubernetes_cluster" "backup_policy_aks" {
  name                            = "backup-policy-aks"
  resource_group_name             = azurerm_data_protection_backup_vault.backup_vault.resource_group_name
  vault_name                      = azurerm_data_protection_backup_vault.backup_vault.name
  backup_repeating_time_intervals = ["R/2026-01-01T00:00:00+00:00/PT4H"] # every 4 hours

  retention_rule {
    name     = "Daily"
    priority = 25

    life_cycle {
      duration        = "P3D"
      data_store_type = "OperationalStore"
    }

    criteria {
      days_of_week           = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      months_of_year         = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
      weeks_of_month         = ["First", "Second", "Third", "Fourth", "Last"]
      scheduled_backup_times = ["2026-05-23T02:30:00Z"]
    }
  }

  default_retention_rule {
    life_cycle {
      duration        = "P3D"
      data_store_type = "OperationalStore"
    }
  }
}
