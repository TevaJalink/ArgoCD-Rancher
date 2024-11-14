resource "aws_acm_certificate" "argocd_cert" {
  domain_name               = "argocd.devops.dcentralab.com"
  validation_method         = "DNS"
  subject_alternative_names = ["argocd.devops.dcentralab.com"]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "argocd-subdomain-cert"
  }
}

resource "aws_route53_record" "argocd_validation" {
  for_each = {
    for dvo in aws_acm_certificate.argocd_cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.devops_subdomain.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 300
}

resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.argocd-ns
  create_namespace = true
  version          = "7.5.2"
  timeout          = 900
  values           = [file("${path.module}/argocd-values.yaml")]

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
    value = tostring(aws_acm_certificate.argocd_cert.arn)
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

  # sync policy ##################################
  set {
    name  = "configs.cm.syncOptions"
    value = "Prune=true,SelfHeal=true"
  }

  # OIDC integration for Okta - ["openid", "profile", "email", "groups"]
  set {
    name = "oidc.config"
    value = yamlencode({
      name            = "Okta"
      issuer          = var.okta_issuer_url
      clientID        = var.okta_client_id_argocd
      clientSecret    = var.okta_client_secret_argocd
      redirectURI     = "https://argocd.devops.dcentralab.com/auth/callback"
      requestedScopes = ["openid", "profile", "email", "groups"]
      requestedIDTokenClaims = {
        emails = { essential = true }
        groups = {
          essential = true
          value     = var.devops_admin_group
        }
      }
    })
  }



  # Disable the default admin user
  #   set {
  #     name  = "configs.cm.accounts.admin"
  #     value = ""
  #   }

  set {
    name  = "rbacConfigMap.enabled"
    value = "true"
  }

  set {
    name  = "configs.cm.url"
    value = "https://argocd.devops.dcentralab.com"
  }
}

data "kubernetes_service" "argocd_service" {
  metadata {
    name      = "argocd-server"
    namespace = helm_release.argocd.namespace
  }
}

resource "aws_route53_record" "argocd" {
  zone_id = aws_route53_zone.devops_subdomain.zone_id
  name    = "argocd.devops.dcentralab.com"
  type    = "CNAME"

  records = [data.kubernetes_service.argocd_service.status[0].load_balancer[0].ingress[0].hostname]
  ttl     = 300
}
