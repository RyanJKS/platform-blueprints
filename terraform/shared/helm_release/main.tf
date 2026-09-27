resource "helm_release" "this" {
  name             = var.release.name
  chart            = var.release.chart
  repository       = var.release.repository
  version          = var.release.version
  namespace        = var.release.namespace
  create_namespace = var.release.create_namespace
  description      = var.release.description

  values        = var.values
  set           = var.set
  set_sensitive = var.set_sensitive

  atomic            = var.release.atomic
  cleanup_on_fail   = var.release.cleanup_on_fail
  dependency_update = var.release.dependency_update
  wait              = var.release.wait
  wait_for_jobs     = var.release.wait_for_jobs
  timeout           = var.release.timeout
  max_history       = var.release.max_history
  skip_crds         = var.release.skip_crds
}
