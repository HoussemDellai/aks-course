# Declare Azure variables

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

variable "azure_resource_group" {
  type        = string
  description = "Resource Group name."
}

variable "azure_vnet_address_space" {
  type        = string
  description = "Address prefix of the virtual network."
  default     = "10.100.0.0/16"
}
  
variable "azure_subnet_address_prefix" {
  type        = string
  description = "Address prefix of the subnet in the virtual network."
  default     = "10.100.0.0/24"
}