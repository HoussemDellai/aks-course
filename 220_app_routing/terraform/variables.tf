variable "prefix" {
  type    = string
  default = "220"
}

variable "location" {
  type    = string
  default = "swedencentral"
}

variable "custom_domain_name" {
  type    = string
  default = "houssemdellai01.com"
  validation {
    condition     = length(var.custom_domain_name) > 0 && (endswith(var.custom_domain_name, ".com") || endswith(var.custom_domain_name, ".net") || endswith(var.custom_domain_name, ".co.uk") || endswith(var.custom_domain_name, ".org") || endswith(var.custom_domain_name, ".nl") || endswith(var.custom_domain_name, ".in") || endswith(var.custom_domain_name, ".biz") || endswith(var.custom_domain_name, ".org.uk") || endswith(var.custom_domain_name, ".co.in"))
    error_message = "Available top level domains are: com, net, co.uk, org, nl, in, biz, org.uk, and co.in"
  }
}
