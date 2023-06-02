data "azurerm_virtual_network" "app_vnet" {
  name                = var.app_vnet_name
  resource_group_name = var.app_vnet_rg
}
