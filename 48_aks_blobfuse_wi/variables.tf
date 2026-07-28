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

variable "container_name" {
  description = "Name of the Container in Storage Account."
  type        = string
  default     = "container-01"
}
