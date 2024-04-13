module "spoke-aks" {
    source = "modules/spoke"
    
    prefix = var.prefix
    location = var.location
    
}