resource "azurerm_monitor_data_collection_rule" "container_insights" {
  count = var.container_insights == null ? 0 : 1

  name                = "MSCI--${azurerm_kubernetes_cluster.this.name}"
  resource_group_name = var.resource_group_name
  location            = local.location
  description         = "DCR for Azure Monitor Container Insights"
  tags                = var.tags

  destinations {
    log_analytics {
      workspace_resource_id = try(var.oms_agent.log_analytics_workspace_id, null)
      name                  = "ciworkspace"
    }
  }
  data_flow {
    streams      = var.container_insights.streams
    destinations = ["ciworkspace"]
  }
  data_sources {
    extension {
      name           = "ContainerInsightsExtension"
      extension_name = "ContainerInsights"
      streams        = var.container_insights.streams
      extension_json = jsonencode({
        dataCollectionSettings = {
          interval               = var.container_insights.data_collection_interval
          namespaceFilteringMode = var.container_insights.namespace_filtering_mode
          namespaces             = var.container_insights.namespaces
          enableContainerLogV2   = var.container_insights.enable_container_log_v2
        }
      })
    }
  }
  lifecycle {
    precondition {
      condition     = try(var.oms_agent.msi_auth_for_monitoring_enabled, false)
      error_message = "container_insights requires oms_agent with msi_auth_for_monitoring_enabled = true."
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "container_insights" {
  count = var.container_insights == null ? 0 : 1

  name                    = "ContainerInsightsExtension"
  target_resource_id      = azurerm_kubernetes_cluster.this.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.container_insights[0].id
  description             = "Association for Container Insights. Deleting it breaks data collection for this cluster."
}
