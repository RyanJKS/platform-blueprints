variable "settings" {
  description = "Shared solution settings. Explicit module inputs take precedence over these defaults."
  type = object({
    name_prefix = string
    region_long = string
    tenant_id   = string
  })
  nullable = false
}

variable "name" {
  description = "Optional resource name override. Defaults to settings.name_prefix followed by aks."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "The name of the existing resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "Optional Azure region override. Defaults to settings.region_long."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to assign to the resource."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "dns_prefix" {
  description = "The DNS prefix for the AKS cluster. Set exactly one of dns_prefix or dns_prefix_private_cluster."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "The Kubernetes version. Null uses the regional Azure default."
  type        = string
  default     = "1.37"
}

variable "default_node_pool" {
  description = "Settings for the default Linux node pool. Omitted attributes use the module defaults."
  type = object({
    name                        = optional(string, "system")
    node_count                  = optional(number, 2)
    auto_scaling_enabled        = optional(bool, false)
    min_count                   = optional(number, 3)
    max_count                   = optional(number, 5)
    max_pods                    = optional(number)
    node_public_ip_enabled      = optional(bool, false)
    temporary_name_for_rotation = optional(string, "rotatingpool")
    zones                       = optional(list(string), [])
    os_disk_size_gb             = optional(number)
    vm_size                     = optional(string, "Standard_D2s_v5")
    vnet_subnet_id              = optional(string)
  })
  default  = {}
  nullable = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,11}$", var.default_node_pool.name))
    error_message = "The node pool name must contain 1 to 12 lowercase letters or digits and start with a letter."
  }

  validation {
    condition     = var.default_node_pool.node_count >= 1 && floor(var.default_node_pool.node_count) == var.default_node_pool.node_count
    error_message = "The node count must be a positive integer."
  }

  validation {
    condition     = var.default_node_pool.min_count >= 1 && floor(var.default_node_pool.min_count) == var.default_node_pool.min_count
    error_message = "min_count must be a positive integer."
  }

  validation {
    condition     = var.default_node_pool.max_count >= 1 && floor(var.default_node_pool.max_count) == var.default_node_pool.max_count
    error_message = "max_count must be a positive integer."
  }

  validation {
    condition     = var.default_node_pool.max_pods == null ? true : var.default_node_pool.max_pods >= 10 && var.default_node_pool.max_pods <= 250 && floor(var.default_node_pool.max_pods) == var.default_node_pool.max_pods
    error_message = "max_pods must be an integer between 10 and 250."
  }

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,11}$", var.default_node_pool.temporary_name_for_rotation))
    error_message = "The rotation name must contain 1 to 12 lowercase letters or digits and start with a letter."
  }

  validation {
    condition     = var.default_node_pool.os_disk_size_gb == null ? true : var.default_node_pool.os_disk_size_gb > 0 && floor(var.default_node_pool.os_disk_size_gb) == var.default_node_pool.os_disk_size_gb
    error_message = "os_disk_size_gb must be a positive integer."
  }
}

variable "identity_ids" {
  description = "User-assigned identity resource IDs. An empty set uses a system-assigned identity."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "admin_group_object_ids" {
  description = "Microsoft Entra group object IDs for cluster administrators."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "private_cluster_enabled" {
  description = "Whether to create a private API server endpoint."
  type        = bool
  default     = true
  nullable    = false
}

variable "oidc_issuer_enabled" {
  description = "Whether to enable the OIDC issuer."
  type        = bool
  default     = true
  nullable    = false
}

variable "workload_identity_enabled" {
  description = "Whether to enable workload identity. Requires the OIDC issuer."
  type        = bool
  default     = true
  nullable    = false
}

variable "sku_tier" {
  description = "The AKS pricing tier."
  type        = string
  default     = "Free"
  nullable    = false

  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "The SKU tier must be Free or Standard."
  }
}

variable "local_account_disabled" {
  description = "Whether local accounts are disabled. Null disables them when Entra integration is enabled."
  type        = bool
  default     = null
}

variable "tenant_id" {
  description = "The Entra tenant ID. Supplying this enables Entra integration even without administrator groups."
  type        = string
  default     = null
}

variable "azure_rbac_enabled" {
  description = "Whether Entra integration uses Azure RBAC rather than Kubernetes RBAC."
  type        = bool
  default     = true
  nullable    = false
}

variable "monitor_metrics" {
  description = "Managed Prometheus metrics settings. Null disables the addon."
  type        = object({ annotations_allowed = optional(string), labels_allowed = optional(string) })
  default     = {}
}

variable "web_app_routing" {
  description = "Application routing settings and Azure DNS zone IDs. Null disables the addon."
  type        = object({ dns_zone_ids = optional(list(string), []), default_nginx_controller = optional(string, "External") })
  default     = {}

  validation {
    condition     = var.web_app_routing == null ? true : contains(["External", "Internal", "None", "AnnotationControlled"], var.web_app_routing.default_nginx_controller)
    error_message = "The default NGINX controller must be External, Internal, None, or AnnotationControlled."
  }
}

variable "dns_prefix_private_cluster" {
  description = "Private cluster DNS prefix. Use instead of dns_prefix with a private cluster and a custom private DNS zone."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone resource ID, System, or None. Null uses the AKS default. Custom zones require caller-managed identity permissions."
  type        = string
  default     = null
}

variable "kubelet_identity" {
  description = "Existing kubelet identity. Requires a user-assigned control-plane identity and caller-managed assignment permissions."
  type = object({
    client_id                 = string
    object_id                 = string
    user_assigned_identity_id = string
  })
  default = null
}

variable "network_profile" {
  description = "AKS networking configuration. The default preserves Azure CNI overlay networking."
  type = object({
    network_plugin      = string
    network_plugin_mode = optional(string)
    network_policy      = optional(string)
    network_data_plane  = optional(string)
    dns_service_ip      = optional(string)
    service_cidr        = optional(string)
    pod_cidr            = optional(string)
    outbound_type       = optional(string, "loadBalancer")
    load_balancer_sku   = optional(string, "standard")
  })
  default  = { network_plugin = "azure", network_plugin_mode = "overlay" }
  nullable = false
}

variable "ingress_application_gateway" {
  description = "Application Gateway ingress using an existing gateway. Null disables the addon."
  type = object({
    gateway_id = string
  })
  default = null
}

variable "key_management_service" {
  description = "Kubernetes secret encryption with an existing Key Vault key. Null disables KMS. Key permissions and private connectivity are caller-managed."
  type = object({
    key_vault_key_id         = string
    key_vault_network_access = optional(string, "Public")
  })
  default = null
  validation {
    condition     = var.key_management_service == null ? true : contains(["Public", "Private"], var.key_management_service.key_vault_network_access)
    error_message = "key_vault_network_access must be Public or Private."
  }
}

variable "oms_agent" {
  description = "Container Insights with an existing Log Analytics workspace. Null disables the addon."
  type = object({
    log_analytics_workspace_id      = string
    msi_auth_for_monitoring_enabled = optional(bool, true)
  })
  default = null
}

variable "additional_node_pools" {
  description = "Additional autoscaled Linux user pools, keyed by pool name. Subnets inherit the default pool subnet when omitted."
  type = map(object({
    vm_size                       = string
    min_count                     = number
    max_count                     = number
    vnet_subnet_id                = optional(string)
    zones                         = optional(list(string), ["1", "2", "3"])
    max_pods                      = optional(number)
    os_disk_type                  = optional(string, "Managed")
    os_disk_size_gb               = optional(number)
    node_labels                   = optional(map(string), {})
    node_taints                   = optional(list(string), [])
    fips_enabled                  = optional(bool, false)
    host_encryption_enabled       = optional(bool, false)
    temporary_name_for_rotation   = optional(string)
    priority                      = optional(string, "Regular")
    eviction_policy               = optional(string, "Delete")
    spot_max_price                = optional(number, -1)
    max_surge                     = optional(string)
    max_unavailable               = optional(string)
    drain_timeout_in_minutes      = optional(number, 60)
    node_soak_duration_in_minutes = optional(number, 3)
    undrainable_node_behavior     = optional(string, "Schedule")
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for name, pool in var.additional_node_pools : can(regex("^[a-z][a-z0-9]{0,11}$", name))])
    error_message = "Pool names must contain 1 to 12 lowercase letters or digits and start with a letter."
  }
  validation {
    condition = alltrue([for pool in values(var.additional_node_pools) :
      pool.min_count >= 0 && floor(pool.min_count) == pool.min_count &&
      pool.max_count >= 1 && floor(pool.max_count) == pool.max_count && pool.min_count <= pool.max_count
    ])
    error_message = "Pool counts must be integers with 0 <= min_count <= max_count and max_count >= 1."
  }
  validation {
    condition     = alltrue([for pool in values(var.additional_node_pools) : contains(["Regular", "Spot"], pool.priority) && contains(["Delete", "Deallocate"], pool.eviction_policy) && (pool.spot_max_price == -1 || pool.spot_max_price >= 0)])
    error_message = "Use Regular or Spot priority, Delete or Deallocate eviction, and a Spot price of -1 or greater than or equal to zero."
  }
  validation {
    condition     = alltrue([for pool in values(var.additional_node_pools) : contains(["Managed", "Ephemeral"], pool.os_disk_type)])
    error_message = "os_disk_type must be Managed or Ephemeral."
  }
  validation {
    condition     = alltrue([for pool in values(var.additional_node_pools) : pool.max_pods == null ? true : pool.max_pods >= 10 && pool.max_pods <= 250 && floor(pool.max_pods) == pool.max_pods])
    error_message = "max_pods must be an integer between 10 and 250."
  }
  validation {
    condition     = alltrue([for pool in values(var.additional_node_pools) : pool.os_disk_size_gb == null ? true : pool.os_disk_size_gb > 0 && floor(pool.os_disk_size_gb) == pool.os_disk_size_gb])
    error_message = "os_disk_size_gb must be a positive integer."
  }
  validation {
    condition     = alltrue([for pool in values(var.additional_node_pools) : pool.temporary_name_for_rotation == null ? true : can(regex("^[a-z][a-z0-9]{0,11}$", pool.temporary_name_for_rotation))])
    error_message = "Rotation names must contain 1 to 12 lowercase letters or digits and start with a letter."
  }
  validation {
    condition     = alltrue([for pool in values(var.additional_node_pools) : !(pool.max_surge != null && pool.max_unavailable != null) && (pool.priority != "Spot" || (pool.max_surge == null && pool.max_unavailable == null))])
    error_message = "Set only one of max_surge and max_unavailable. Spot pools do not support these upgrade settings."
  }
  validation {
    condition     = alltrue([for pool in values(var.additional_node_pools) : contains(["Schedule", "Cordon"], pool.undrainable_node_behavior)])
    error_message = "undrainable_node_behavior must be Schedule or Cordon."
  }
}

variable "container_insights" {
  description = "Optional Container Insights data collection rule for the oms_agent workspace. Requires oms_agent with managed identity authentication."
  type = object({
    streams                  = optional(set(string), ["Microsoft-ContainerInsights-Group-Default"])
    data_collection_interval = optional(string, "1m")
    namespace_filtering_mode = optional(string, "Off")
    namespaces               = optional(list(string), [])
    enable_container_log_v2  = optional(bool, true)
  })
  default = null

  validation {
    condition     = var.container_insights == null ? true : contains(["1m", "5m", "10m", "15m", "30m"], var.container_insights.data_collection_interval)
    error_message = "data_collection_interval must be 1m, 5m, 10m, 15m, or 30m."
  }
  validation {
    condition     = var.container_insights == null ? true : contains(["Off", "Include", "Exclude"], var.container_insights.namespace_filtering_mode)
    error_message = "namespace_filtering_mode must be Off, Include, or Exclude."
  }
  validation {
    condition     = var.container_insights == null ? true : length(var.container_insights.streams) > 0
    error_message = "At least one Container Insights stream is required."
  }
}
