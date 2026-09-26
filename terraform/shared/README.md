# Shared modules

Cloud-independent Terraform modules:

- [Kubernetes manifest](kubernetes_manifest/README.md): Apply Kubernetes resources, including Argo CD Applications.

- [Helm release](helm_release/README.md): Install a Helm chart on an existing Kubernetes cluster.

This grouping directory is not a Terraform module. Configure providers and state in the consuming repository.
