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
}

resource "azurerm_storage_container" "calombo" {
  name                  = "calombo"
  storage_account_name  = azurerm_storage_account.procon.name
  container_access_type = "container"
}

resource "azurerm_storage_account_queue_properties" "example" {
  storage_account_id = azurerm_storage_account.procon.id
  logging {
    version                = "1.0"
    delete                 = true
    read                   = true
    write                  = true
    retention_policy_days  = 7
  }

  hour_metrics {
    version                = "1.0"
    retention_policy_days  = 7
  }

  minute_metrics {
    version                = "1.0"
    retention_policy_days  = 7
  }
}

resource "azurerm_key_vault" "kv" {
  name                = "kv-assessment-app"
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

resource "azurerm_mssql_server" "example" {
  name                         = "examplesqlserver"
  resource_group_name          = azurerm_resource_group.example.name
  location                     = azurerm_resource_group.example.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "H@Sh1CoR3!"
}

resource "azurerm_mssql_database" "example" {
  name      = "exampledb"
  server_id = azurerm_mssql_server.example.id
  sku_name  = "S0"
}

 

resource "azurerm_kubernetes_cluster" "example" {
  name                = "exampleaks"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "exampleaks"
  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "null_resource" "configure_kubernetes" {
  provisioner "local-exec" {
    command = <<EOT
      az aks get-credentials --resource-group ${azurerm_resource_group.example.name} --name ${azurerm_kubernetes_cluster.example.name}
    EOT
  }
  depends_on = [azurerm_kubernetes_cluster.example]
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.example.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.client_key)
 cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_namespace" "example" {
  metadata {
    name = "example-namespace"
  }
  depends_on = [null_resource.configure_kubernetes]
}
