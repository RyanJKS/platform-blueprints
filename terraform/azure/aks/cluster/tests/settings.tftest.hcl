mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  dns_prefix          = "test-aks"
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
    tenant_id   = "11111111-1111-1111-1111-111111111111"
  }
}

run "settings_defaults" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster.this.name == "paymentsuksdevaks" && azurerm_kubernetes_cluster.this.location == "uksouth"
    error_message = "Shared settings must supply the default resource name and location."
  }
}

run "explicit_overrides" {
  command = plan
  variables {
    name     = "explicit-resource"
    location = "westeurope"
  }
  assert {
    condition     = azurerm_kubernetes_cluster.this.name == "explicit-resource" && azurerm_kubernetes_cluster.this.location == "westeurope"
    error_message = "Explicit inputs must override shared settings."
  }
}

run "settings_do_not_enable_entra" {
  command = plan
  assert {
    condition     = length(azurerm_kubernetes_cluster.this.azure_active_directory_role_based_access_control) == 0
    error_message = "Passing shared identity settings must not enable Entra integration."
  }
}

run "entra_uses_shared_tenant" {
  command = plan
  variables {
    admin_group_object_ids = ["22222222-2222-2222-2222-222222222222"]
  }
  assert {
    condition     = azurerm_kubernetes_cluster.this.azure_active_directory_role_based_access_control[0].tenant_id == var.settings.tenant_id
    error_message = "Enabled Entra integration must use the shared tenant when no override is provided."
  }
}
