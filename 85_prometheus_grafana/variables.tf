variable "resources_location" {
  type    = string
  default = "swedencentral"
}

variable "rg_aks_cluster" {
  type    = string
  default = "rg-aks-cluster-swc"
}

variable "rg_monitoring" {
  type    = string
  default = "rg-monitoring-swc"
}

variable "aks_name" {
  type    = string
  default = "aks-cluster"
}

variable "grafana_name" {
  type    = string
  default = "azure-grafana-swc"
}

variable "prometheus_name" {
  type    = string
  default = "azure-prometheus"
}
