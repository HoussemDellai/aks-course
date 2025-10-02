variable "location" {
  description = "The Azure region to deploy resources in"
  type        = string
  default     = "francecentral" # "swedencentral"

}

variable "prefix" {
  description = "The prefix to use for resources"
  type        = string
  default     = "750"
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
