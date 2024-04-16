# App Service Domain
# REST API reference: https://docs.microsoft.com/en-us/rest/api/appservice/domains/createorupdate
resource "azapi_resource" "appservice_domain" {
  type                      = "Microsoft.DomainRegistration/domains@2022-09-01"
  name                      = var.custom_domain_name
  parent_id                 = azurerm_resource_group.rg.id
  location                  = "global"
  schema_validation_enabled = true
  response_export_values    = ["*"] # ["id", "name", "properties.nameServers"]

  body = jsonencode({

    properties = {
      autoRenew = false
      dnsType   = "AzureDns"
      dnsZoneId = azurerm_dns_zone.dns_zone.id
      privacy   = false

      consent = {
        agreementKeys = ["DNRA"]
        agreedBy      = "2a04:cec0:11d9:24c8:8898:3820:8631:d83"
        agreedAt      = "2024-04-16T11:50:59.264Z"
      }

      contactAdmin = {
        nameFirst = "FirstName"
        nameLast  = "LastName"
        email     = "youremail@email.com" # you might get verification email
        phone     = "+33.762954328"
        addressMailing = {
          address1   = "1 Microsoft Way"
          city       = "Redmond"
          state      = "WA"
          country    = "US"
          postalCode = "98052"
        }
      }

      contactRegistrant = {
        nameFirst = "FirstName"
        nameLast  = "LastName"
        email     = "youremail@email.com" # you might get verification email
        phone     = "+33.762954328"
        addressMailing = {
          address1   = "1 Microsoft Way"
          city       = "Redmond"
          state      = "WA"
          country    = "US"
          postalCode = "98052"
        }
      }

      contactBilling = {
        nameFirst = "FirstName"
        nameLast  = "LastName"
        email     = "youremail@email.com" # you might get verification email
        phone     = "+33.762954328"
        addressMailing = {
          address1   = "1 Microsoft Way"
          city       = "Redmond"
          state      = "WA"
          country    = "US"
          postalCode = "98052"
        }
      }

      contactTech = {
        nameFirst = "FirstName"
        nameLast  = "LastName"
        email     = "youremail@email.com" # you might get verification email
        phone     = "+33.762954328"
        addressMailing = {
          address1   = "1 Microsoft Way"
          city       = "Redmond"
          state      = "WA"
          country    = "US"
          postalCode = "98052"
        }
      }
    }
  })
}

