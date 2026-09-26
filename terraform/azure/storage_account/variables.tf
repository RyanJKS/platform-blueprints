variable "settings" {
  description = "Shared solution settings. Explicit module inputs take precedence over defaults."
  type = object({
    name_prefix = string
    region_long = string
  })
  nullable = false
}

variable "name" {
  description = "Optional globally unique account name. Defaults to settings.name_prefix followed by sa."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "The name of an existing resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "Optional Azure region override. Defaults to settings.region_long."
  type        = string
  default     = null
}

variable "account_replication_type" {
  description = "The replication type. Availability depends on the Azure region."
  type        = string
  default     = "LRS"
  nullable    = false

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "The replication type must be LRS, GRS, RAGRS, ZRS, GZRS, or RAGZRS."
  }
}

variable "access_tier" {
  description = "The default access tier for blobs."
  type        = string
  default     = "Hot"
  nullable    = false

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "The access tier must be Hot or Cool."
  }
}

variable "public_network_access_enabled" {
  description = "Whether to allow access through the public network endpoint. Configure private endpoints separately when false."
  type        = bool
  default     = false
  nullable    = false
}

variable "shared_access_key_enabled" {
  description = "Whether to allow Shared Key authorization. Disabled by default to require Microsoft Entra authorization for supported services."
  type        = bool
  default     = false
  nullable    = false
}

variable "tags" {
  description = "Tags to assign to the storage account."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "account_kind" {
  description = "The storage account kind. Changes may replace the account."
  type        = string
  default     = "StorageV2"
  nullable    = false
  validation {
    condition     = contains(["Storage", "StorageV2", "BlobStorage", "BlockBlobStorage", "FileStorage"], var.account_kind)
    error_message = "account_kind must be one of: Storage, StorageV2, BlobStorage, BlockBlobStorage, FileStorage."
  }
}

variable "account_tier" {
  description = "The account performance tier. Changes replace the account."
  type        = string
  default     = "Standard"
  nullable    = false
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be one of: Standard, Premium."
  }
}

variable "is_hns_enabled" {
  description = "Enable the hierarchical namespace for Data Lake Storage Gen2."
  type        = bool
  default     = false
  nullable    = false
}

variable "sftp_enabled" {
  description = "Enable SFTP. Requires HNS and local users; provision local users separately."
  type        = bool
  default     = false
  nullable    = false
}

variable "local_user_enabled" {
  description = "Enable local user authentication, including SFTP users."
  type        = bool
  default     = true
  nullable    = false
}

variable "nfsv3_enabled" {
  description = "Enable Blob NFS v3. Requires HNS and network-based access controls."
  type        = bool
  default     = false
  nullable    = false
}

variable "large_file_share_enabled" {
  description = "Enable large Azure file shares where supported."
  type        = bool
  default     = false
  nullable    = false
}

variable "infrastructure_encryption_enabled" {
  description = "Enable infrastructure encryption. Changes replace the account."
  type        = bool
  default     = false
  nullable    = false
}

variable "cross_tenant_replication_enabled" {
  description = "Allow object replication across Microsoft Entra tenants."
  type        = bool
  default     = false
  nullable    = false
}

variable "allowed_copy_scope" {
  description = "Restrict copy operations to AAD or PrivateLink; null leaves the scope unrestricted."
  type        = string
  default     = null
  validation {
    condition     = var.allowed_copy_scope == null ? true : contains(["AAD", "PrivateLink"], var.allowed_copy_scope)
    error_message = "allowed_copy_scope must be one of: AAD, PrivateLink."
  }
}

variable "queue_encryption_key_type" {
  description = "Use a Service or Account encryption key for Queue storage."
  type        = string
  default     = "Service"
  nullable    = false
  validation {
    condition     = contains(["Service", "Account"], var.queue_encryption_key_type)
    error_message = "queue_encryption_key_type must be one of: Service, Account."
  }
}

variable "table_encryption_key_type" {
  description = "Use a Service or Account encryption key for Table storage."
  type        = string
  default     = "Service"
  nullable    = false
  validation {
    condition     = contains(["Service", "Account"], var.table_encryption_key_type)
    error_message = "table_encryption_key_type must be one of: Service, Account."
  }
}

variable "https_traffic_only_enabled" {
  description = "Require HTTPS. Set false explicitly for workloads such as NFS that require HTTP."
  type        = bool
  default     = true
  nullable    = false
}

variable "default_to_oauth_authentication" {
  description = "Default to Microsoft Entra authorization in the Azure portal."
  type        = bool
  default     = true
  nullable    = false
}

variable "identity" {
  description = "Optional identity settings. Omitted attributes use AzureRM defaults. See the README for prerequisites."
  type = object({
    identity_ids = optional(set(string))
    type         = string
  })
  default = null
}

variable "network_rules" {
  description = "Optional network rules settings. Omitted attributes use AzureRM defaults. See the README for prerequisites."
  type = object({
    bypass                     = optional(set(string))
    default_action             = string
    ip_rules                   = optional(set(string))
    virtual_network_subnet_ids = optional(set(string))
    private_link_access = optional(list(object({
      endpoint_resource_id = string
      endpoint_tenant_id   = optional(string)
    })), [])
  })
  default = null
}

variable "blob_properties" {
  description = "Optional blob properties settings. Omitted attributes use AzureRM defaults. See the README for prerequisites."
  type = object({
    change_feed_enabled           = optional(bool)
    change_feed_retention_in_days = optional(number)
    default_service_version       = optional(string)
    last_access_time_enabled      = optional(bool)
    versioning_enabled            = optional(bool)
    container_delete_retention_policy = optional(object({
      days = optional(number)
    }))
    cors_rule = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })), [])
    delete_retention_policy = optional(object({
      days                     = optional(number)
      permanent_delete_enabled = optional(bool)
    }))
    restore_policy = optional(object({
      days = number
    }))
  })
  default = null
}

variable "share_properties" {
  description = "Optional share properties settings. Omitted attributes use AzureRM defaults. See the README for prerequisites."
  type = object({
    cors_rule = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })), [])
    retention_policy = optional(object({
      days = optional(number)
    }))
    smb = optional(object({
      authentication_types            = optional(set(string))
      channel_encryption_type         = optional(set(string))
      kerberos_ticket_encryption_type = optional(set(string))
      multichannel_enabled            = optional(bool)
      versions                        = optional(set(string))
    }))
  })
  default = null
}

variable "azure_files_authentication" {
  description = "Optional azure files authentication settings. Omitted attributes use AzureRM defaults. See the README for prerequisites."
  type = object({
    default_share_level_permission = optional(string)
    directory_type                 = string
    active_directory = optional(object({
      domain_guid         = string
      domain_name         = string
      domain_sid          = optional(string)
      forest_name         = optional(string)
      netbios_domain_name = optional(string)
      storage_sid         = optional(string)
    }))
  })
  default = null
}

variable "routing" {
  description = "Optional routing settings. Omitted attributes use AzureRM defaults. See the README for prerequisites."
  type = object({
    choice                      = optional(string)
    publish_internet_endpoints  = optional(bool)
    publish_microsoft_endpoints = optional(bool)
  })
  default = null
}

variable "custom_domain" {
  description = "Optional custom domain settings. Omitted attributes use AzureRM defaults. See the README for prerequisites."
  type = object({
    name          = string
    use_subdomain = optional(bool)
  })
  default = null
}

variable "customer_managed_key" {
  description = "Optional customer managed key settings. Omitted attributes use AzureRM defaults. See the README for prerequisites."
  type = object({
    key_vault_key_id          = string
    user_assigned_identity_id = string
  })
  default = null
}
