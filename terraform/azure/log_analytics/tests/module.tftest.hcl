mock_provider "azurerm" {
  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/paymentsuksdevlaw"
      workspace_id = "11111111-1111-1111-1111-111111111111"
    }
  }
}

variables {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
  }
  resource_group_name = "rg-test"
}

run "defaults" {
  command = plan

  assert {
    condition = (
      output.name == "paymentsuksdevlaw" &&
      output.location == "uksouth" &&
      azurerm_log_analytics_workspace.this.resource_group_name == "rg-test" &&
      azurerm_log_analytics_workspace.this.sku == "PerGB2018" &&
      azurerm_log_analytics_workspace.this.retention_in_days == 30 &&
      azurerm_log_analytics_workspace.this.daily_quota_gb == -1 &&
      !azurerm_log_analytics_workspace.this.local_authentication_enabled &&
      azurerm_log_analytics_workspace.this.allow_resource_only_permissions &&
      azurerm_log_analytics_workspace.this.internet_ingestion_access_type == "Enabled" &&
      azurerm_log_analytics_workspace.this.internet_query_access_type == "Enabled"
    )
    error_message = "Defaults must use shared naming and region, pay-as-you-go pricing, 30-day retention, unlimited ingestion, and Entra authentication."
  }
}

run "explicit_overrides" {
  command = plan

  variables {
    name                               = "law-example"
    location                           = "westeurope"
    sku                                = "CapacityReservation"
    reservation_capacity_in_gb_per_day = 100
    retention_in_days                  = 90
    daily_quota_gb                     = 50.5
    local_authentication_enabled       = true
    allow_resource_only_permissions    = false
    internet_ingestion_access_type     = "Disabled"
    internet_query_access_type         = "SecuredByPerimeter"
    tags                               = { environment = "test" }
  }

  assert {
    condition = (
      output.name == "law-example" &&
      output.location == "westeurope" &&
      output.tags["environment"] == "test" &&
      azurerm_log_analytics_workspace.this.sku == "CapacityReservation" &&
      azurerm_log_analytics_workspace.this.reservation_capacity_in_gb_per_day == 100 &&
      azurerm_log_analytics_workspace.this.retention_in_days == 90 &&
      azurerm_log_analytics_workspace.this.daily_quota_gb == 50.5 &&
      azurerm_log_analytics_workspace.this.local_authentication_enabled &&
      !azurerm_log_analytics_workspace.this.allow_resource_only_permissions &&
      azurerm_log_analytics_workspace.this.internet_ingestion_access_type == "Disabled" &&
      azurerm_log_analytics_workspace.this.internet_query_access_type == "SecuredByPerimeter"
    )
    error_message = "Explicit inputs must override shared settings and workspace defaults."
  }
}

run "connection_outputs" {
  command = apply

  assert {
    condition = (
      output.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/paymentsuksdevlaw" &&
      output.workspace_id == "11111111-1111-1111-1111-111111111111"
    )
    error_message = "The module must expose the Azure resource ID separately from the workspace customer GUID."
  }
}

run "reject_invalid_generated_name" {
  command = plan
  variables {
    settings = {
      name_prefix = "-invalid"
      region_long = "uksouth"
    }
  }
  expect_failures = [azurerm_log_analytics_workspace.this]
}

run "reject_invalid_retention" {
  command = plan
  variables {
    retention_in_days = 29
  }
  expect_failures = [var.retention_in_days]
}

run "reject_fractional_retention" {
  command = plan
  variables {
    retention_in_days = 30.5
  }
  expect_failures = [var.retention_in_days]
}

run "reject_invalid_quota" {
  command = plan
  variables {
    daily_quota_gb = -2
  }
  expect_failures = [var.daily_quota_gb]
}

run "reject_invalid_sku" {
  command = plan
  variables {
    sku = "Invalid"
  }
  expect_failures = [var.sku]
}

run "reject_reservation_without_capacity_sku" {
  command = plan
  variables {
    reservation_capacity_in_gb_per_day = 100
  }
  expect_failures = [azurerm_log_analytics_workspace.this]
}

run "reject_capacity_sku_without_reservation" {
  command = plan
  variables {
    sku = "CapacityReservation"
  }
  expect_failures = [azurerm_log_analytics_workspace.this]
}

run "reject_invalid_capacity" {
  command = plan
  variables {
    sku                                = "CapacityReservation"
    reservation_capacity_in_gb_per_day = 75
  }
  expect_failures = [var.reservation_capacity_in_gb_per_day]
}

run "reject_invalid_ingestion_access" {
  command = plan
  variables {
    internet_ingestion_access_type = "Invalid"
  }
  expect_failures = [var.internet_ingestion_access_type]
}

run "reject_invalid_query_access" {
  command = plan
  variables {
    internet_query_access_type = "Invalid"
  }
  expect_failures = [var.internet_query_access_type]
}
