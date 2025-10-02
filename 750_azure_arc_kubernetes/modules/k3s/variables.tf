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

variable "github_account" {
  type        = string
  description = "Target GitHub account."
  default     = "microsoft"
}

variable "github_branch" {
  type        = string
  description = "Target GitHub branch."
  default     = "main"
}

variable "bastion_subnet_prefix" {
  type        = string
  description = "Azure Bastion subnet IP prefix."
  default     = "172.16.2.64/26"
}

variable "azure_resource_group" {
  type        = string
  description = "Resource Group name."
}

variable "azure_vnet_address_space" {
  type        = string
  description = "Address prefix of the virtual network."
  default     = "172.16.0.0/16"
}

variable "azure_vnet_subnet" {
  type        = string
  description = "Name of the subnet in the virtual network."
  default     = "subnet"
}

variable "azure_subnet_address_prefix" {
  type        = string
  description = "Address prefix of the subnet in the virtual network."
  default     = "172.16.1.0/24"
}