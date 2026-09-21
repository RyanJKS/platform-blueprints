variable "name" {
  description = "The resource name."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "The name of the existing resource group."
  type        = string
  nullable    = false
}

variable "location" {
  description = "The Azure region in which to create the resource."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Tags to assign to the resource."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "dns_prefix" {
  description = "The DNS prefix for the AKS cluster."
  type        = string
  nullable    = false
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
