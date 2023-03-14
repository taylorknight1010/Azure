resource "azurerm_private_dns_zone" "dns" {
  name                = var.dns_zone
  resource_group_name = var.resource_group_name
  tags = var.tags
}
