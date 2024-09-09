resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "7.5.2"

  # load balancer for argocd-server - look into using VPN and migrating to NodePort
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
    value = var.ssl_certificate_arn
  }

  set {
    name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-backend-protocol"
    value = "HTTP"
  }

  set {
    name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-ports"
    value = "443"
  }

  # HA configuration
  set {
    name  = "server.replicas"
    value = "3"
  }

  set {
    name  = "controller.replicas"
    value = "3"
  }

  set {
    name  = "repoServer.replicas"
    value = "3"
  }

  set {
    name  = "redis.enabled"
    value = "true"
  }

  set {
    name  = "controller.enableLeaderElection"
    value = "true"
  }

  set {
    name  = "repoServer.enableLeaderElection"
    value = "true"
  }

  # sync policy
  set {
    name  = "configs.cm.syncOptions"
    value = "[\"Prune=true\", \"SelfHeal=true\"]"
  }

  # OIDC integration for Okta
  set {
    name  = "configs.cm.oidc.config"
    value = <<-EOT
    name: Okta
    issuer: ${var.okta_issuer_url}
    clientID: ${var.okta_client_id_argocd}
    clientSecret: ${var.okta_client_secret_argocd} # this needs to be passed as a pipeline variable at the terraform plan/apply level
    requestedScopes: ["openid", "profile", "email", "groups"]
    requestedIDTokenClaims: |
      emails:
        essential: true
      groups:
        essential: true
        value: ${var.devops_admin_group}
    EOT
  }

  # Disable the default admin user
  set {
    name  = "configs.cm.accounts.admin"
    value = ""
  }

  # Set RBAC policies in argocd-rbac-cm
  set {
    name  = "configs.rbac.policy.csv"
    value = <<-EOT
      g, oidc:<ADMIN_GROUP>, role:admin
      g, oidc:<READONLY_GROUP>, role:readonly
    EOT
  }

  depends_on = [module.eks-devops]
}

data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = helm_release.argocd.namespace
  }
}