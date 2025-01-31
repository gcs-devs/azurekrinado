# Configuração do Provider Azure
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}


provider "azurerm" {
  features {}
}


# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-assessment-app"
  location = "eastus2"
}


# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-assessment"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-assessment"


  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }


  identity {
    type = "SystemAssigned"
  }
}


# Azure Key Vault
resource "azurerm_key_vault" "kv" {
  name                = "kv-assessment-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id          = data.azurerm_client_config.current.tenant_id
  sku_name           = "standard"


  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id


    secret_permissions = [
      "Get", "List"
    ]
  }
}


# Azure Database for PostgreSQL
resource "azurerm_postgresql_server" "db" {
  name                = "psql-assessment-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name


  sku_name = "B_Gen5_1"


  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled           = true


  administrator_login          = "psqladmin"
  administrator_login_password = "H@Sh1CoR3!"
  version                     = "11"
  ssl_enforcement_enabled     = true
}


# Key Vault Secret
resource "azurerm_key_vault_secret" "db_connection" {
  name         = "DB-CONNECTION-STRING"
  value        = "postgresql://${azurerm_postgresql_server.db.administrator_login}:${azurerm_postgresql_server.db.administrator_login_password}@${azurerm_postgresql_server.db.fqdn}:5432/postgres?sslmode=require"
  key_vault_id = azurerm_key_vault.kv.id
}