variable "prefix" {
  type        = string
  description = "Lowercase naming prefix for the demo resources."
  default     = "aks-arc"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,19}[a-z0-9]$", var.prefix))
    error_message = "Use 3-21 lowercase letters, digits or hyphens, starting with a letter and ending with a letter or digit."
  }
}

variable "location" {
  type        = string
  description = "Azure region supporting AKS, Azure Arc-enabled Kubernetes and the selected VM size."
  default     = "swedencentral"
}

variable "node_vm_size" {
  type        = string
  description = "Linux system pool VM size for all three demo clusters."
  default     = "Standard_D2as_v5"
}

variable "node_count" {
  type        = number
  description = "System pool nodes per cluster. One is sufficient for this demo, not for production availability."
  default     = 1

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 10 && floor(var.node_count) == var.node_count
    error_message = "node_count must be an integer between 1 and 10."
  }
}

variable "kubernetes_version" {
  type        = string
  description = "Optional supported AKS version. Null uses the regional AKS default at creation."
  default     = null
}

variable "api_server_authorized_ip_ranges" {
  type        = set(string)
  description = "Public IPv4 CIDRs allowed to reach the API servers. Include the Terraform runner's egress IP. Empty leaves the endpoints unrestricted."
  default     = []

  validation {
    condition     = alltrue([for cidr in var.api_server_authorized_ip_ranges : can(cidrnetmask(cidr))])
    error_message = "Each API server authorized range must be a valid IPv4 CIDR."
  }
}