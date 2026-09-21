resource "azurerm_role_assignment" "this" {
  for_each = var.assignments

  name                             = each.value.name
  scope                            = each.value.scope
  principal_id                     = each.value.principal_id
  principal_type                   = each.value.type
  role_definition_name             = each.value.role_definition_name
  role_definition_id               = each.value.role_definition_id
  description                      = each.value.description
  condition                        = each.value.condition
  condition_version                = each.value.condition == null ? null : "2.0"
  skip_service_principal_aad_check = each.value.skip_service_principal_aad_check

  lifecycle {
    precondition {
      condition     = (each.value.role_definition_name != null) != (each.value.role_definition_id != null)
      error_message = "Set exactly one of role_definition_name or role_definition_id."
    }
    precondition {
      condition     = !each.value.skip_service_principal_aad_check || each.value.type == "ServicePrincipal"
      error_message = "skip_service_principal_aad_check is only valid for type ServicePrincipal."
    }
  }
}
