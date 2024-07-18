variable "prefix" {
  type    = string
  default = "240"
}

variable "location" {
  type    = string
  default = "swedencentral"
}

# variable "location" {
#   type    = string
#   default = "westus3"
# }

variable "front_door_private_link_location" {
  type    = string
  default = "swedencentral"
}

variable "waf_mode" {
  type    = string
  default = "Prevention"
}

variable "custom_domain_name" {
  type    = string
  default = "contoso.fabrikam.com"
}