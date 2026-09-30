mock_provider "azurerm" {
  mock_resource "azurerm_kubernetes_cluster" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/test" }
  }
  mock_resource "azurerm_monitor_data_collection_rule" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Insights/dataCollectionRules/test" }
  }
}

variables {
  settings = {
    name_prefix = "test"
    region_long = "uksouth"
    tenant_id   = "11111111-1111-1111-1111-111111111111"
  }
  resource_group_name = "rg-test"
  dns_prefix          = "test"
}

run "monitoring_disabled" {
  command = plan
  assert {
    condition     = length(azurerm_monitor_data_collection_rule.container_insights) == 0 && length(azurerm_monitor_data_collection_rule_association.container_insights) == 0
    error_message = "DCR and association must remain opt-in."
  }
}

run "configured_monitoring" {
  command = apply
  variables {
    oms_agent = {
      log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/test"
    }
    container_insights = {
      streams                  = ["Microsoft-ContainerLogV2"]
      data_collection_interval = "5m"
      namespace_filtering_mode = "Exclude"
      namespaces               = ["kube-system"]
    }
  }
  assert {
    condition = (
      azurerm_monitor_data_collection_rule.container_insights[0].destinations[0].log_analytics[0].workspace_resource_id == var.oms_agent.log_analytics_workspace_id &&
      toset(azurerm_monitor_data_collection_rule.container_insights[0].data_flow[0].streams) == var.container_insights.streams &&
      jsondecode(azurerm_monitor_data_collection_rule.container_insights[0].data_sources[0].extension[0].extension_json).dataCollectionSettings == {
        interval = "5m", namespaceFilteringMode = "Exclude", namespaces = ["kube-system"], enableContainerLogV2 = true
      } &&
      azurerm_monitor_data_collection_rule_association.container_insights[0].target_resource_id == azurerm_kubernetes_cluster.this.id &&
      azurerm_monitor_data_collection_rule_association.container_insights[0].data_collection_rule_id == output.container_insights_data_collection_rule_id
    )
    error_message = "Container Insights must use the OMS workspace, serialize collection settings, and associate the rule with the cluster."
  }
}

run "reject_missing_agent" {
  command = plan
  variables { container_insights = {} }
  expect_failures = [azurerm_monitor_data_collection_rule.container_insights]
}

run "reject_legacy_auth" {
  command = plan
  variables {
    container_insights = {}
    oms_agent = {
      log_analytics_workspace_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/test"
      msi_auth_for_monitoring_enabled = false
    }
  }
  expect_failures = [azurerm_monitor_data_collection_rule.container_insights]
}

run "reject_invalid_interval" {
  command = plan
  variables { container_insights = { data_collection_interval = "2m" } }
  expect_failures = [var.container_insights]
}
