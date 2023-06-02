##################
# Resource Group #
##################

resource "azurerm_resource_group" "app_rg" {
  name     = var.app_rg_name
  location = var.location
}

############
# Subnet Creation #
############
resource "azurerm_subnet" "integrationsubnet" {
  name                 = var.integration_subnet_name
  resource_group_name  = data.azurerm_virtual_network.app_vnet.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.app_vnet.name
  address_prefixes     = var.subnet_integration_ap
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}
resource "azurerm_subnet" "web_ep_subnet" {
  name                 = var.web_ep_subnet_name
  resource_group_name  = data.azurerm_virtual_network.app_vnet.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.app_vnet.name
  address_prefixes     = var.subnet_web_ap
}
resource "azurerm_subnet" "sa_ep_subnet" {
  name                 = var.sa_ep_subnet_name
  resource_group_name  = data.azurerm_virtual_network.app_vnet.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.app_vnet.name
  address_prefixes     = var.subnet_sa_ap

}
resource "azurerm_subnet" "sql_ep_subnet" {
  name                 = var.sql_ep_subnet_name
  resource_group_name  = data.azurerm_virtual_network.app_vnet.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.app_vnet.name
  address_prefixes     = var.subnet_sql_ap
}

############
# DNS Zone Creation #
############

resource "azurerm_private_dns_zone" "web-dnsprivatezone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = data.azurerm_virtual_network.app_vnet.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "web-dnszonelink" {
  name = "web_dnszonelink"
  resource_group_name = data.azurerm_virtual_network.app_vnet.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.web-dnsprivatezone.name
  virtual_network_id = data.azurerm_virtual_network.app_vnet.id
}

resource "azurerm_private_dns_zone" "sql-dnsprivatezone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = data.azurerm_virtual_network.app_vnet.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql-dnszonelink" {
  name = "sql_dnszonelink"
  resource_group_name   = data.azurerm_virtual_network.app_vnet.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql-dnsprivatezone.name
  virtual_network_id    = data.azurerm_virtual_network.app_vnet.id
}

resource "azurerm_private_dns_zone" "sa-dnsprivatezone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_virtual_network.app_vnet.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sa-dnszonelink" {
  name = "sa_dnszonelink"
  resource_group_name   = data.azurerm_virtual_network.app_vnet.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sa-dnsprivatezone.name
  virtual_network_id    = data.azurerm_virtual_network.app_vnet.id
}

############
# Web App #
############

resource "azurerm_service_plan" "app_asp" {
  name                = var.app_asp_name
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  os_type = "Windows"
  sku_name = "P1v3"
  zone_balancing_enabled = true
  worker_count = 3
 }

resource "azurerm_windows_web_app" "web_app" {
  name                = var.web_app_name
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  service_plan_id     = azurerm_service_plan.app_asp.id
  https_only          = true
  virtual_network_subnet_id = azurerm_subnet.integrationsubnet.id

  identity {
    type = "SystemAssigned"
  }
  
  site_config {
    ftps_state               = "FtpsOnly"
    always_on                = true
    vnet_route_all_enabled   = true
    application_stack {
      current_stack = "dotnet"
      dotnet_version = "v7.0"
    }
  }
  app_settings = {
    "ApplicationInsights__InstrumentationKey" = azurerm_application_insights.app_ai.instrumentation_key
  }

  connection_string {
    name  = "sqlConnection"
    type  = "SQLServer"
    value = "Server=tcp:${azurerm_mssql_server.app_sql_server.name}.database.windows.net,1433;Initial Catalog=${azurerm_mssql_database.app_sql_db.name};Persist Security Info=False;User ID=4dm1n157r470r;Password=${random_password.sqlpassword.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Max Pool Size=200;Connection Timeout=30;"
  }
  connection_string {
    name = "AzureStorage"
    type = "Custom"
    value = azurerm_storage_account.app_sa.primary_connection_string
  }
}

resource "azurerm_private_endpoint" "app_web-pe" {
  name                = "backwebappprivateendpoint"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  subnet_id           = azurerm_subnet.web_ep_subnet.id

  private_dns_zone_group {
    name = "privatednszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.web-dnsprivatezone.id]
  }

  private_service_connection {
    name = "privateendpointconnection"
    private_connection_resource_id = azurerm_windows_web_app.web_app.id
    subresource_names = ["sites"]
    is_manual_connection = false
  }
}

#####################################
#    Azure Application Insights     #
#####################################

resource "azurerm_application_insights" "app_ai" {
  name                = var.app_ai
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  application_type    = "web"
}

##############################
#   Storage Account Setup    #
##############################

resource "azurerm_storage_account" "app_sa" {
  name                     = var.app_sa_name
  location                 = var.location
  resource_group_name      = azurerm_resource_group.app_rg.name
  account_tier             = var.app_sa_account_tier
  account_replication_type = var.app_sa_replication_type
  account_kind = var.app_sa_account_kind
  enable_https_traffic_only        = true
  allow_nested_items_to_be_public  = false
}

resource "azurerm_private_endpoint" "app_sa_pe" {
  name                = var.app_sa_pe_name
  location            = var.location
  resource_group_name = azurerm_resource_group.app_rg.name
  subnet_id           = azurerm_subnet.sa_ep_subnet.id

  private_dns_zone_group {
    name = "privatednszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.sa-dnsprivatezone.id]
  }
  private_service_connection { 
    name = var.app_sa_pe_name
    private_connection_resource_id = azurerm_storage_account.app_sa.id
    is_manual_connection = false
    subresource_names = ["blob"]
  }
}

###########################################
##### Adding a Blob Storage Container #####
###########################################

resource "azurerm_storage_container" "app_sa_cn" {
  name                  = var.app_sa_container_name
  storage_account_name  = azurerm_storage_account.app_sa.name
  container_access_type = var.app_sa_container_access_type
}

#######################
#### Azure SQL DB #####
#######################

resource "azurerm_mssql_server" "app_sql_server" {
  name                         = var.app_sql_server_name
  location                     = azurerm_resource_group.app_rg.location
  resource_group_name          = azurerm_resource_group.app_rg.name
  version                      = "12.0"
  administrator_login          = "appxadmin"
  administrator_login_password = random_password.sqlpassword.result  #uses random password generated below
  minimum_tls_version          = "1.2"
}

resource "azurerm_mssql_database" "app_sql_db" {
  name                         = var.app_sql_db_name
  server_id                    = azurerm_mssql_server.app_sql_server.id
  collation                    = "SQL_Latin1_General_CP1_CI_AS"
  sku_name                     = "P1"
  zone_redundant               = true

}

resource "azurerm_private_endpoint" "app_sql_pe" {
  name                = var.app_sql_pe_name
  location            = var.location
  resource_group_name = azurerm_resource_group.app_rg.name
  subnet_id           = azurerm_subnet.sql_ep_subnet.id

  private_dns_zone_group {
    name = "privatednszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql-dnsprivatezone.id]
  }
  private_service_connection { 
    name = var.app_sql_pe_name
    private_connection_resource_id = azurerm_mssql_server.app_sql_server.id
    is_manual_connection = false
    subresource_names = ["sqlServer"]
  }
}

##################################################
# Configure Terraform random password generator  #
##################################################

resource "random_password" "sqlpassword" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}