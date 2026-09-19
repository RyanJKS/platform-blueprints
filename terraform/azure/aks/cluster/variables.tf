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
  default     = null
}

variable "node_pool_name" {
  description = "The name of the default Linux node pool."
  type        = string
  default     = "system"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,11}$", var.node_pool_name))
    error_message = "The node pool name must contain 1 to 12 lowercase letters or digits and start with a letter."
  }
}

variable "node_count" {
  description = "The number of nodes in the system node pool when autoscaling is disabled."
  type        = number
  default     = 2
  nullable    = false

  validation {
    condition     = var.node_count >= 1 && floor(var.node_count) == var.node_count
    error_message = "The node count must be a positive integer."
  }
}

variable "vm_size" {
  description = "The virtual machine size for system nodes."
  type        = string
  default     = "Standard_D2s_v5"
  nullable    = false
}

variable "vnet_subnet_id" {
  description = "An existing subnet ID for the nodes. Null lets AKS manage networking."
  type        = string
  default     = null
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

variable "auto_scaling_enabled" {
  description = "Whether the default node pool uses the cluster autoscaler."
  type        = bool
  default     = false
  nullable    = false
}

variable "min_count" {
  description = "The minimum node count when autoscaling is enabled."
  type        = number
  default     = 3
  nullable    = false

  validation {
    condition     = var.min_count >= 1 && floor(var.min_count) == var.min_count
    error_message = "min_count must be a positive integer."
  }
}

variable "max_count" {
  description = "The maximum node count when autoscaling is enabled."
  type        = number
  default     = 5
  nullable    = false

  validation {
    condition     = var.max_count >= 1 && floor(var.max_count) == var.max_count
    error_message = "max_count must be a positive integer."
  }
}

variable "max_pods" {
  description = "The maximum pods per node. Null uses the AKS default."
  type        = number
  default     = null

  validation {
    condition     = var.max_pods == null ? true : var.max_pods >= 10 && var.max_pods <= 250 && floor(var.max_pods) == var.max_pods
    error_message = "max_pods must be an integer between 10 and 250."
  }
}

variable "node_public_ip_enabled" {
  description = "Whether nodes receive public IP addresses."
  type        = bool
  default     = false
  nullable    = false
}

variable "temporary_name_for_rotation" {
  description = "The temporary node pool name for changes that require rotation."
  type        = string
  default     = "rotatingpool"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,11}$", var.temporary_name_for_rotation))
    error_message = "The rotation name must contain 1 to 12 lowercase letters or digits and start with a letter."
  }
}

variable "zones" {
  description = "Availability zones for the default node pool."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "os_disk_size_gb" {
  description = "The OS disk size in GB. Null uses the AKS default."
  type        = number
  default     = null

  validation {
    condition     = var.os_disk_size_gb == null ? true : var.os_disk_size_gb > 0 && floor(var.os_disk_size_gb) == var.os_disk_size_gb
    error_message = "os_disk_size_gb must be a positive integer."
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
  default     = null
}

variable "web_app_routing" {
  description = "Application routing settings and Azure DNS zone IDs. Null disables the addon."
  type        = object({ dns_zone_ids = optional(list(string), []), default_nginx_controller = optional(string, "External") })
  default     = null

  validation {
    condition     = var.web_app_routing == null ? true : contains(["External", "Internal", "None", "AnnotationControlled"], var.web_app_routing.default_nginx_controller)
    error_message = "The default NGINX controller must be External, Internal, None, or AnnotationControlled."
  }
}
