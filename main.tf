provider "azurerm" {
  features {}
  subscription_id = "830edc45-1a69-46d2-8598-c4cdb195fd4c"
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "brazilsouth"
}

resource "azurerm_disk_access" "setup" {
  name                = var.diskAccesses_setup_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_data_share_account" "teste" {
  name                = var.accounts_teste_name
  location            = "southcentralus"
  resource_group_name = azurerm_resource_group.example.name
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_account" "procon" {
  name                     = var.storageAccounts_procon_name
  location                 = azurerm_resource_group.example.location
  resource_group_name      = azurerm_resource_group.example.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
  queue_properties {}
}

resource "azurerm_storage_container" "calombo" {
  name                  = "calombo"
  storage_account_name  = azurerm_storage_account.procon.name
  container_access_type = "container"
} 

resource "azurerm_key_vault" "kv" {
  name                = "examplekeyvault"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
} 

resource "azurerm_key_vault_secret" "db_connection" {
  name         = "db-connection-string"
  value        = "your-db-connection-string"
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_access_policy" "example" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  secret_permissions = [
    "Get",
    "List",
  ]
}
