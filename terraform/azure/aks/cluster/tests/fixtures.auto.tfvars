# Shared inputs automatically loaded by Terraform for tests in this directory.
settings = {
  name_prefix = "paymentsuksdev"
  region_long = "uksouth"
  tenant_id   = "11111111-1111-1111-1111-111111111111"
}

resource_group_name = "rg-test"
dns_prefix          = "test-aks"
key_vault_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/test"
