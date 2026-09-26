output "manifest" {
  description = "The desired Kubernetes manifest. May contain sensitive values."
  value       = kubernetes_manifest.this.manifest
  sensitive   = true
}

output "object" {
  description = "The resulting Kubernetes object, including server-populated fields. May contain sensitive values."
  value       = kubernetes_manifest.this.object
  sensitive   = true
}

output "name" {
  description = "The requested Kubernetes resource name."
  value       = var.manifest.metadata.name
}

output "namespace" {
  description = "The requested namespace, or null when omitted."
  value       = try(var.manifest.metadata.namespace, null)
}

output "kind" {
  description = "The Kubernetes resource kind."
  value       = var.manifest.kind
}

output "api_version" {
  description = "The Kubernetes API group and version."
  value       = var.manifest.apiVersion
}
