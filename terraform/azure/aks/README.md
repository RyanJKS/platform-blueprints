# Azure Kubernetes Service

This directory groups independently deployable AKS modules:

- [Cluster](cluster/README.md): AKS cluster, system node pool, identity, managed Prometheus settings, and application routing settings.
- [Extension](extension/README.md): Azure-managed Kubernetes extensions for an existing AKS cluster.

Additional node pools and other independently managed extensions can become sibling modules when needed. This grouping directory is not a Terraform module.

## Migration

The cluster source has moved from `azure/aks` to `azure/aks/cluster`. Keep the existing module call name and state to preserve cluster resource addresses. Networking sources have moved beneath `azure/networking/`; the same rule applies.

Extensions now use a separate generic module. Remove the cluster `argocd` input and translate its settings using the [extension migration guidance](extension/README.md#migration-from-argocd_extension). Connect `cluster_id` to the cluster `id` output. Replace consumers of the old `argocd_extension_id` output with the extension `id` output.

If Argo CD is already deployed, migrate its state before applying. Within one Terraform root and state, use a `moved` block with your actual module names:

```hcl
moved {
  from = module.aks.azurerm_kubernetes_cluster_extension.argocd[0]
  to   = module.argocd.azurerm_kubernetes_cluster_extension.extension
}
```

For separate Terragrunt states, back up both states and coordinate removal from the old state and import into the extension state. Do not apply an intermediate plan that destroys the extension. Review the final plans for resource replacement before applying.
