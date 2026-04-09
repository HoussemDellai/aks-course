# prefix
variable "prefix" {
  type        = string
  description = "Prefix for resource names"
  default     = "270"
}

variable "location" {
  type        = string
  description = "Resources location in Azure"
  default     = "swedencentral"
}
