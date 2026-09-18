resource "azurerm_role_assignment" "this" {
  name                             = var.name
  scope                            = var.scope
  principal_id                     = var.principal_id
  principal_type                   = var.type
  role_definition_name             = var.role_definition_name
  role_definition_id               = var.role_definition_id
  description                      = var.description
  condition                        = var.condition
  condition_version                = var.condition == null ? null : "2.0"
  skip_service_principal_aad_check = var.skip_service_principal_aad_check

  lifecycle {
    precondition {
      condition     = (var.role_definition_name != null) != (var.role_definition_id != null)
      error_message = "Set exactly one of role_definition_name or role_definition_id."
    }
    precondition {
      condition     = !var.skip_service_principal_aad_check || var.type == "ServicePrincipal"
      error_message = "skip_service_principal_aad_check is only valid for type ServicePrincipal."
    }
  }
}
