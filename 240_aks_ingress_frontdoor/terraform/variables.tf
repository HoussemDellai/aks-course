variable "prefix" {
  type    = string
  default = "240-dev"
}

variable "location" {
  type    = string
  default = "swedencentral"
}

variable "pls_service_name" {
  type    = string
  default = "pls-aks-service"
}

variable "pls_ingress_name" {
  type    = string
  default = "pls-aks-ingress"
}

variable "aks_service_ip" {
  type    = string
  default = "10.10.0.25"
}

variable "aks_ingress_ip" {
  type    = string
  default = "10.10.0.30"
}
