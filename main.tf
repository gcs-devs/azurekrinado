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
