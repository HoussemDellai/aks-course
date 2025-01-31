To deploy these resources via Terraform, you will need to have the following installed on your machine:

```sh
$env:ARM_SUBSCRIPTION_ID=(az account show --query id -o tsv)

# Set the following environment variable if you are using Linux
# export ARM_CLIENT_ID=(az account show --query id -o tsv)

terraform init

terraform plan -out tfplan

terraform apply tfplan
```