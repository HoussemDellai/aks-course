variable "prefix" {
  default = "48"
}

variable "service_account_namespace" {
  description = "Kubernetes namespace containing the workload identity service account."
  type        = string
  default     = "default"
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account used by the workload."
  type        = string
  default     = "service-account-01"
}

variable "rg_name" {
  description = "Resource group of the Storage Account."
  type        = string
  default     = "rg-aks-blob-adls-wi-48"
}

variable "storage_account_name" {
  description = "Name of the Storage Account to be created."
  type        = string
  default     = "stor4adls4aks48"
}

variable "container_name" {
  description = "Name of the Container in Storage Account."
  type        = string
  default     = "container-01"
}
