variable "prefix" {
  default = "preprod"
}

variable "aks" {
  # type = list(string)
  default = [
    {
      cluster_name = "aks-cluster-1",
      version      = "1.34.2",
      os           = "AzureLinux", # | Ubuntu
      node_count   = 1
    },
    {
      cluster_name = "aks-cluster-2",
      version      = "1.33.11",
      os           = "Ubuntu", # | Ubuntu
      node_count   = 2
    },
    {
      cluster_name = "aks-cluster-3",
      version      = "1.35.4",
      os           = "AzureLinux", # | Ubuntu
      node_count   = 1
    },
    {
      cluster_name = "aks-cluster-4",
      version      = "1.34.7",
      os           = "AzureLinux", # | Ubuntu
      node_count   = 1
    },
    # {
    #   cluster_name = "aks-cluster-2",
    #   version      = "1.33.3",
    #   os           = "Windows2022", # | Ubuntu
    #   node_count   = 2
    # },
  ]
}
