variable "prefix" {
  type    = string
  default = "241"
}

variable "location" {
  type    = string
}

variable "resource_group_name" {
  type    = string
}

variable "pls_ingress_name" {
  type    = string
  default = "pls-aks-ingress"
}

variable "aks_ingress_ip" {
  type    = string
  default = "10.10.0.30"
}