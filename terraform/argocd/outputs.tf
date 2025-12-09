output "argocd_namespace" {
  value = kubernetes_namespace.argo.metadata[0].name
}

output "argocd_release_name" {
  value = helm_release.argo.name
}

