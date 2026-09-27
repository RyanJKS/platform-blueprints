resource "kubernetes_manifest" "this" {
  manifest        = var.manifest
  computed_fields = var.computed_fields

  field_manager {
    name            = var.field_manager.name
    force_conflicts = var.field_manager.force_conflicts
  }

  dynamic "wait" {
    for_each = var.wait_fields == null ? [] : [var.wait_fields]
    content {
      fields = wait.value
    }
  }

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}
