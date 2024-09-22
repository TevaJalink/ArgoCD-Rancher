resource "kubernetes_manifest" "argocd_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.repo_name
      namespace = var.argo_namespace
    }
    spec = {
      project = var.project_name
      source = {
        repoURL        = var.repo_url
        path           = var.manifest_path
        targetRevision = var.tragetRevision
      }
      destination = {
        server    = var.eks_cluster_api_url
        namespace = var.destination_ns
      }
      syncPolicy = {
        automated = {
          prune    = var.prune
          selfHeal = var.selfheal
        }
      }
    }
  }
}