mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "11111111-1111-1111-1111-111111111111"
      tenant_id       = "22222222-2222-2222-2222-222222222222"
      client_id       = "33333333-3333-3333-3333-333333333333"
      object_id       = "44444444-4444-4444-4444-444444444444"
    }
  }
}

variables {
  solution_name = " Payments API! "
  env           = "dev"
  region_short  = "uks"
  region_long   = "uksouth"
  tags          = { owner = "platform" }
}

run "shared_settings_contract" {
  command = apply
  assert {
    condition     = output.settings.solution_slug == "payments-api" && output.settings.name_prefix == "payments-apiuksdev"
    error_message = "The shared name prefix must combine the normalized solution name, region, and environment."
  }
  assert {
    condition     = output.tags == var.tags && !contains(keys(output.settings), "tags")
    error_message = "Tags must remain a separate pass-through output."
  }
  assert {
    condition     = output.settings.tenant_id == "22222222-2222-2222-2222-222222222222" && output.settings.subscription_id == "11111111-1111-1111-1111-111111111111" && output.settings.client_id == "33333333-3333-3333-3333-333333333333" && output.settings.object_id == "44444444-4444-4444-4444-444444444444"
    error_message = "All identity fields must come from the configured AzureRM provider."
  }
}
