variable "location" { default = "westeurope" }
variable "rg_name" { default = "rg-aks-agc-waf" }
variable "allowed_ip_cidrs" {
  default = ["203.0.113.10/32"]
}
