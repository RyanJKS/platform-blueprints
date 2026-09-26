mock_provider "azurerm" {}

variables {
  settings            = { name_prefix = "paymentsuksdev", region_long = "uksouth" }
  resource_group_name = "rg-test"
}

run "sftp_and_hns" {
  command = plan
  variables {
    is_hns_enabled = true
    sftp_enabled   = true
  }
  assert {
    condition     = azurerm_storage_account.this.is_hns_enabled && azurerm_storage_account.this.sftp_enabled && azurerm_storage_account.this.local_user_enabled
    error_message = "SFTP must enable HNS and retain local user authentication."
  }
}

run "premium_nfs" {
  command = plan
  variables {
    account_kind               = "BlockBlobStorage"
    account_tier               = "Premium"
    is_hns_enabled             = true
    nfsv3_enabled              = true
    https_traffic_only_enabled = false
    network_rules = {
      default_action = "Deny"
      bypass         = ["None"]
      ip_rules       = ["203.0.113.10"]
    }
  }
  assert {
    condition     = azurerm_storage_account.this.nfsv3_enabled && !azurerm_storage_account.this.https_traffic_only_enabled && azurerm_storage_account.this.account_tier == "Premium" && azurerm_storage_account.this.network_rules[0].default_action == "Deny"
    error_message = "Premium NFS and network settings must reach the account."
  }
}

run "blob_protection_and_identity" {
  command = plan
  variables {
    identity                          = { type = "SystemAssigned" }
    infrastructure_encryption_enabled = true
    blob_properties = {
      versioning_enabled                = true
      change_feed_enabled               = true
      change_feed_retention_in_days     = 30
      delete_retention_policy           = { days = 14 }
      container_delete_retention_policy = { days = 14 }
      restore_policy                    = { days = 7 }
      cors_rule = [{
        allowed_headers    = ["*"]
        allowed_methods    = ["GET"]
        allowed_origins    = ["https://example.com"]
        exposed_headers    = ["ETag"]
        max_age_in_seconds = 3600
      }]
    }
  }
  assert {
    condition     = azurerm_storage_account.this.blob_properties[0].restore_policy[0].days == 7 && azurerm_storage_account.this.blob_properties[0].delete_retention_policy[0].days == 14 && azurerm_storage_account.this.blob_properties[0].cors_rule[0].allowed_methods == tolist(["GET"]) && azurerm_storage_account.this.identity[0].type == "SystemAssigned" && azurerm_storage_account.this.infrastructure_encryption_enabled
    error_message = "Blob protection, CORS, and identity settings must be preserved."
  }
}

run "file_service_settings" {
  command = plan
  variables {
    account_kind = "FileStorage"
    account_tier = "Premium"
    share_properties = {
      retention_policy = { days = 14 }
      smb              = { versions = ["SMB3.1.1"] }
    }
    azure_files_authentication = { directory_type = "AADKERB" }
    routing                    = { choice = "MicrosoftRouting", publish_microsoft_endpoints = true }
  }
  assert {
    condition     = azurerm_storage_account.this.share_properties[0].retention_policy[0].days == 14 && azurerm_storage_account.this.azure_files_authentication[0].directory_type == "AADKERB" && azurerm_storage_account.this.routing[0].publish_microsoft_endpoints
    error_message = "Azure Files and routing settings must be preserved."
  }
}

run "reject_sftp_without_hns" {
  command = plan
  variables { sftp_enabled = true }
  expect_failures = [azurerm_storage_account.this]
}

run "reject_sftp_without_local_users" {
  command = plan
  variables {
    sftp_enabled       = true
    is_hns_enabled     = true
    local_user_enabled = false
  }
  expect_failures = [azurerm_storage_account.this]
}

run "reject_nfs_without_hns" {
  command = plan
  variables { nfsv3_enabled = true }
  expect_failures = [azurerm_storage_account.this]
}

run "reject_hns_versioning" {
  command = plan
  variables {
    is_hns_enabled  = true
    blob_properties = { versioning_enabled = true }
  }
  expect_failures = [azurerm_storage_account.this]
}

run "reject_standard_file_storage" {
  command = plan
  variables { account_kind = "FileStorage" }
  expect_failures = [azurerm_storage_account.this]
}

run "reject_restore_without_prerequisites" {
  command = plan
  variables { blob_properties = { restore_policy = { days = 7 } } }
  expect_failures = [azurerm_storage_account.this]
}
