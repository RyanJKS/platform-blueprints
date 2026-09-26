locals {
  name        = coalesce(var.name, "${var.settings.name_prefix}sa")
  location    = coalesce(var.location, var.settings.region_long)
  access_tier = contains(["StorageV2", "BlobStorage"], var.account_kind) ? var.access_tier : null

}

resource "azurerm_storage_account" "this" {
  name                            = local.name
  resource_group_name             = var.resource_group_name
  location                        = local.location
  account_kind                    = var.account_kind
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  access_tier                     = local.access_tier
  https_traffic_only_enabled      = var.https_traffic_only_enabled
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access           = var.public_network_access_enabled ? "Enabled" : "Disabled"
  shared_access_key_enabled       = var.shared_access_key_enabled
  default_to_oauth_authentication = var.default_to_oauth_authentication
  tags                            = var.tags

  is_hns_enabled                    = var.is_hns_enabled
  sftp_enabled                      = var.sftp_enabled
  local_user_enabled                = var.local_user_enabled
  nfsv3_enabled                     = var.nfsv3_enabled
  large_file_share_enabled          = var.large_file_share_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  cross_tenant_replication_enabled  = var.cross_tenant_replication_enabled
  allowed_copy_scope                = var.allowed_copy_scope
  queue_encryption_key_type         = var.queue_encryption_key_type
  table_encryption_key_type         = var.table_encryption_key_type

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      identity_ids = identity.value.identity_ids
      type         = identity.value.type
    }
  }
  dynamic "network_rules" {
    for_each = var.network_rules == null ? [] : [var.network_rules]
    content {
      bypass                     = network_rules.value.bypass
      default_action             = network_rules.value.default_action
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
      dynamic "private_link_access" {
        for_each = network_rules.value.private_link_access
        content {
          endpoint_resource_id = private_link_access.value.endpoint_resource_id
          endpoint_tenant_id   = private_link_access.value.endpoint_tenant_id
        }
      }
    }
  }
  dynamic "blob_properties" {
    for_each = var.blob_properties == null ? [] : [var.blob_properties]
    content {
      change_feed_enabled           = blob_properties.value.change_feed_enabled
      change_feed_retention_in_days = blob_properties.value.change_feed_retention_in_days
      default_service_version       = blob_properties.value.default_service_version
      last_access_time_enabled      = blob_properties.value.last_access_time_enabled
      versioning_enabled            = blob_properties.value.versioning_enabled
      dynamic "container_delete_retention_policy" {
        for_each = blob_properties.value.container_delete_retention_policy == null ? [] : [blob_properties.value.container_delete_retention_policy]
        content {
          days = container_delete_retention_policy.value.days
        }
      }
      dynamic "cors_rule" {
        for_each = blob_properties.value.cors_rule
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }
      dynamic "delete_retention_policy" {
        for_each = blob_properties.value.delete_retention_policy == null ? [] : [blob_properties.value.delete_retention_policy]
        content {
          days                     = delete_retention_policy.value.days
          permanent_delete_enabled = delete_retention_policy.value.permanent_delete_enabled
        }
      }
      dynamic "restore_policy" {
        for_each = blob_properties.value.restore_policy == null ? [] : [blob_properties.value.restore_policy]
        content {
          days = restore_policy.value.days
        }
      }
    }
  }
  dynamic "share_properties" {
    for_each = var.share_properties == null ? [] : [var.share_properties]
    content {
      dynamic "cors_rule" {
        for_each = share_properties.value.cors_rule
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }
      dynamic "retention_policy" {
        for_each = share_properties.value.retention_policy == null ? [] : [share_properties.value.retention_policy]
        content {
          days = retention_policy.value.days
        }
      }
      dynamic "smb" {
        for_each = share_properties.value.smb == null ? [] : [share_properties.value.smb]
        content {
          authentication_types            = smb.value.authentication_types
          channel_encryption_type         = smb.value.channel_encryption_type
          kerberos_ticket_encryption_type = smb.value.kerberos_ticket_encryption_type
          multichannel_enabled            = smb.value.multichannel_enabled
          versions                        = smb.value.versions
        }
      }
    }
  }
  dynamic "azure_files_authentication" {
    for_each = var.azure_files_authentication == null ? [] : [var.azure_files_authentication]
    content {
      default_share_level_permission = azure_files_authentication.value.default_share_level_permission
      directory_type                 = azure_files_authentication.value.directory_type
      dynamic "active_directory" {
        for_each = azure_files_authentication.value.active_directory == null ? [] : [azure_files_authentication.value.active_directory]
        content {
          domain_guid         = active_directory.value.domain_guid
          domain_name         = active_directory.value.domain_name
          domain_sid          = active_directory.value.domain_sid
          forest_name         = active_directory.value.forest_name
          netbios_domain_name = active_directory.value.netbios_domain_name
          storage_sid         = active_directory.value.storage_sid
        }
      }
    }
  }
  dynamic "routing" {
    for_each = var.routing == null ? [] : [var.routing]
    content {
      choice                      = routing.value.choice
      publish_internet_endpoints  = routing.value.publish_internet_endpoints
      publish_microsoft_endpoints = routing.value.publish_microsoft_endpoints
    }
  }
  dynamic "custom_domain" {
    for_each = var.custom_domain == null ? [] : [var.custom_domain]
    content {
      name          = custom_domain.value.name
      use_subdomain = custom_domain.value.use_subdomain
    }
  }
  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key == null ? [] : [var.customer_managed_key]
    content {
      key_vault_key_id          = customer_managed_key.value.key_vault_key_id
      user_assigned_identity_id = customer_managed_key.value.user_assigned_identity_id
    }
  }

  lifecycle {
    precondition {
      condition     = var.blob_properties == null ? true : (var.blob_properties.restore_policy == null ? true : (var.blob_properties.versioning_enabled == true && var.blob_properties.change_feed_enabled == true && try(var.blob_properties.delete_retention_policy.days > var.blob_properties.restore_policy.days, false)))
      error_message = "Blob restore requires versioning, change feed, and delete retention longer than the restore window."
    }
    precondition {
      condition     = !var.is_hns_enabled || !(try(var.blob_properties.versioning_enabled, false) == true || try(var.blob_properties.change_feed_enabled, false) == true || try(var.blob_properties.restore_policy, null) != null)
      error_message = "HNS does not support blob versioning, change feed, or point-in-time restore."
    }
    precondition {
      condition     = !contains(["BlockBlobStorage", "FileStorage"], var.account_kind) || var.account_tier == "Premium"
      error_message = "BlockBlobStorage and FileStorage require the Premium tier."
    }
    precondition {
      condition     = !(var.is_hns_enabled || var.sftp_enabled || var.nfsv3_enabled) || contains(["StorageV2", "BlockBlobStorage"], var.account_kind)
      error_message = "HNS, SFTP, and NFS v3 require StorageV2 or BlockBlobStorage."
    }
    precondition {
      condition     = !var.nfsv3_enabled || var.is_hns_enabled
      error_message = "NFS v3 requires HNS."
    }
    precondition {
      condition     = !var.sftp_enabled || (var.is_hns_enabled && var.local_user_enabled)
      error_message = "SFTP requires HNS and local users to be enabled."
    }
    precondition {
      condition     = can(regex("^[a-z0-9]{3,24}$", local.name))
      error_message = "The resolved storage account name must contain 3 to 24 lowercase letters or digits. Set name to override an invalid generated name."
    }
  }
}
