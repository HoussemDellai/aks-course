variable "prefix" {
  type    = string
  default = "103"
}

variable "location" {
  type    = string
  default = "swedencentral"
}

variable "spokes" {
  default = {
    01 = ["10.1.0.0/16"],
    02 = ["10.2.0.0/16"]
  }
}
