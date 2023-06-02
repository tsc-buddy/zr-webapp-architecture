variable app_rg_name {
    type = string
    description = "Application resource group"
}

variable "location" {
    description = "Your deployment region"
    type = string
}

variable "app_asp_name" {
    type = string
    description = "app service plan for both web apps"
}

variable "web_app_name" {
    type = string
    description = "app service for front end apps"
}

variable "app_ai" {
    type = string
    description = "app insigts service for front end app"
}

variable "app_sa_name" {
    type = string
    description = "Storage Account - stores audio files, gtfs files, device updates, logs."
}

variable "app_sa_container_name" {
    type = string
    description = "Container blob"
}

variable "app_sa_container_access_type" {
    type = string
    description = "container_access"
}

variable "app_sa_account_tier" {
    type = string
    description = "SA account tier for obc setup"
    default = "Standard"
}

variable "app_sa_account_kind" {
    type = string
    description = "SA Container type for obc setup"
    default = "StorageV2"
}

variable "app_sa_replication_type" {
    type = string
    description = "SA Replication type "
    default = "ZRS"
}

variable "app_sql_server_name" {
    type = string
    description = "Azure SQL Server Name"
}

variable "app_sql_db_name" {
    type = string
    description = "Azure SQL DB Name"
}


variable "app_vnet_name" {
    type = string
    description = "vnet name for app LZ"
}

variable "app_vnet_rg" {
    type = string
    description = "name of app vnet resource group"
}

variable "integration_subnet_name" {
    type = string
    description = "Address prefix for Integration subnet"
}
variable "web_ep_subnet_name" {
    type = string
    description = "Address prefix for web private endpoint subnet"
}
variable "sa_ep_subnet_name" {
    type = string
    description = "Address prefix for storage account private endpoint subnet"
}
variable "sql_ep_subnet_name" {
    type = string
    description = "Address prefix for Azure SQL private endpoint subnet"
}

variable "subnet_integration_ap" {
    type = list(string)
    description = "Address prefix for Integration subnet"
}

variable "subnet_web_ap" {
    type = list(string)
    description = "Address prefix for web private endpoint subnet"
}

variable "subnet_sa_ap" {
    type = list(string)
    description = "Address prefix for storage account private endpoint subnet"
}

variable "subnet_sql_ap" {
    type = list(string)
    description = "Address prefix for Azure SQL private endpoint subnet"
}

variable "app_sa_pe_name" {
    type = string
    description = "name of sa private endpoint"
}

variable "app_sql_pe_name" {
    type = string
    description = "name of sql private endpoint"
}