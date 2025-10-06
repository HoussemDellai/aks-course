variable "prefix" {
  type        = string
  description = "Prefix for all resources."
}

variable "location" {
  type        = string
  description = "Location for all resources."
}

variable "client_id" {
  type        = string
  description = "Unique SPN app ID."
}
variable "client_secret" {
  type        = string
  description = "Unique SPN password."
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  description = "Unique SPN tenant ID"
}

variable "rg_name" {
  type        = string
  description = "Resource Group name."
}

variable "vm_name" {
  type        = string
  description = "Virtual Machine name."
}

variable "vnet_address_space" {
  type        = string
  description = "Address prefix of the virtual network."
}
  
variable "subnet_address_prefix" {
  type        = string
  description = "Address prefix of the subnet in the virtual network."
}

variable "firewall_private_ip" {
  type        = string
  description = "Private IP address of the Azure Firewall."
}

variable "vnet_hub_rg" {
  type        = string
  description = "Resource Group name of the hub virtual network."
}

variable "vnet_hub_name" {
  type        = string
  description = "Name of the hub virtual network."
} 

variable "vnet_hub_id" {
  type        = string
  description = "ID of the hub virtual network."
}

variable "prometheus_resource_id" {
  type        = string
  description = "Resource ID of the Prometheus workspace."
}

variable "grafana_resource_id" {
  type        = string
  description = "Resource ID of the Grafana workspace."
}

variable "log_analytics_resource_id" {
  type        = string
  description = "Resource ID of the Log Analytics workspace."
}