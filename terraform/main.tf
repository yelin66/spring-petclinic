provider "azurerm" {
    features {}
    #version = "=2.20.0"
}

resource "azurerm_resource_group" "example" {
    location = var.location
    name     = "tmp-spring-petclinic"

    tags     = {
        "Terraform" = "true"
    }
}

resource "azurerm_mysql_server" "example" {
  name                             = "tmp-ly-spring-petclinic"
  location                         = azurerm_resource_group.example.location
  resource_group_name              = azurerm_resource_group.example.name

  administrator_login              = "mysqladminun"
  administrator_login_password     = "H@Sh1CoR3!"

  sku_name                         = "B_Gen5_1"
  storage_mb                       = 5120
  version                          = "5.7"

  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"
}

resource "azurerm_mysql_database" "example" {
  name                = "petclinic"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mysql_server.example.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

resource "azurerm_mysql_firewall_rule" "example" {
  name                = "office"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_mysql_server.example.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_app_service_plan" "example" {
  name                = "tmp-ly-plan"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "PremiumV2"
    size = "P1v2"
  }
}

resource "azurerm_app_service" "example" {
  name                = "tmp-ly-petclinic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  app_service_plan_id = azurerm_app_service_plan.example.id

  https_only          = true

  site_config {
    linux_fx_version  = "JAVA|11-java11"
  }

  app_settings = {
    "SPRING_PROFILES_ACTIVE" = "mysql"
    "SPRING_DATASOURCE_URL" = "jdbc:mysql://${azurerm_mysql_server.example.fqdn}:3306/${azurerm_mysql_database.example.name}?useUnicode=true&characterEncoding=utf8&useSSL=true&useLegacyDatetime=false&serverTimezone=UTC"
    "SPRING_DATASOURCE_USERNAME" = "${azurerm_mysql_server.example.administrator_login}@${azurerm_mysql_server.example.name}"
    "SPRING_DATASOURCE_PASSWORD" = azurerm_mysql_server.example.administrator_login_password
  }
}