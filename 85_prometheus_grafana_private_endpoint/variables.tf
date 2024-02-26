variable "resources_location" {
  type    = string
  default = "swedencentral"
}

variable "rg_aks_cluster" {
  type    = string
  default = "rg-aks-cluster2"
}

variable "rg_monitoring" {
  type    = string
  default = "rg-monitoring2"
}

variable "aks_name" {
  type    = string
  default = "aks-cluster2"
}

variable "grafana_name" {
  type    = string
  default = "azure-grafana-15"
}

variable "prometheus_name" {
  type    = string
  default = "azure-prometheus"
}
