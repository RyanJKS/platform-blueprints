output "id" {
  description = "The Helm release resource ID."
  value       = helm_release.this.id
}

output "name" {
  description = "The Helm release name."
  value       = helm_release.this.name
}

output "namespace" {
  description = "The Kubernetes namespace containing the release."
  value       = helm_release.this.namespace
}

output "status" {
  description = "The status of the deployed Helm release."
  value       = helm_release.this.status
}
