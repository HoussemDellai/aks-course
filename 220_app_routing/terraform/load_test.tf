# resource "azurerm_load_test" "load_test" {
#   name                = "load-test"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
# }

# resource "terraform_data" "create-load-test" {
#   provisioner "local-exec" {
#     command = <<-EOF
#       az load test create --load-test-resource  ${azurerm_load_test.load_test.name} -g ${azurerm_load_test.load_test.resource_group_name} --test-id testwebapp --test-plan testplan.jmx --engine-instances 1
#     EOF
#   }

#   triggers_replace = [azurerm_load_test.load_test.id]
# }

# resource "terraform_data" "run-load-test" {
#   provisioner "local-exec" {
#     command = <<-EOF
#       az load test-run create --load-test-resource  ${azurerm_load_test.load_test.name} -g ${azurerm_load_test.load_test.resource_group_name} --test-id testwebapp --test-run-id testwebapprun1
#     EOF
#   }

#   triggers_replace = [azurerm_load_test.load_test.id]

#   depends_on = [terraform_data.create-load-test]
# }
