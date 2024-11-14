data "aws_caller_identity" "current" {}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "v1.13.0"

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "global.leaderElection.namespace"
    value = "cert-manager"
  }
}

resource "random_password" "rancher_user" {
  length  = 16
  special = false
  numeric = true
  upper   = true
  lower   = true
}

resource "helm_release" "ingress-nginx" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.11.3"
  create_namespace = true
  timeout          = 900

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}

resource "helm_release" "rancher" {
  name             = "rancher"
  namespace        = "cattle-system"
  repository       = "https://releases.rancher.com/server-charts/stable"
  chart            = "rancher"
  version          = "2.9.1"
  create_namespace = true
  timeout          = 900
  values           = [file("${path.module}/rancher-values.yaml")]

  set {
    name  = "hostname"
    value = var.rancher_hostname
  }

  set {
    name  = "replicas"
    value = "3"
  }

  # there is no way do disable admin, only manually from the UI or with more complex automation
  set {
    name  = "bootstrapPassword"
    value = random_password.rancher_user.result # Default admin password for Rancher
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "ingress.tls.source"
    value = "letsEncrypt"
  }

  set {
    name  = "ingress.ingressClassName"
    value = "nginx"
  }

  set {
    name  = "letsEncrypt.email"
    value = "teva.jalink@dcentralab.com"
  }

  set {
    name  = "letsEncrypt.ingress.class"
    value = "nginx"
  }

  depends_on = [
    helm_release.cert_manager
  ]
}

data "kubernetes_service" "nginx_controller" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
  depends_on = [
    helm_release.rancher
  ]
}

resource "aws_route53_record" "rancher" {
  zone_id = aws_route53_zone.devops_subdomain.zone_id
  name    = "rancher.devops.dcentralab.com"
  type    = "CNAME"

  records = [data.kubernetes_service.nginx_controller.status[0].load_balancer[0].ingress[0].hostname]
  ttl     = 300
}

resource "null_resource" "patch_genericoidc" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "${base64decode(module.eks-devops.cluster_certificate_authority_data)}" > /tmp/ca.crt
      kubectl patch authconfig genericoidc --type=merge -p '{
        "status": {
          "conditions": [
            {
              "status": "True",
              "type": "SecretsMigrated"
            }
          ]
        },
        "accessMode": "unrestricted",
        "allowedPrincipalIds": [
          "genericoidc_user://00uhj51hpt6sUxLng697"
        ],
        "clientId": "0oaj1uxk5iyEoIUaY697",
        "clientSecret": "b9tcG0lq4S-ibkKegjsToMr4Y6xtcMT5o-j62UQYrBcv5JDlNx_OtFtX6jbPkluE",
        "enabled": true,
        "groupSearchEnabled": true,
        "issuer": "https://dcentralab.okta.com",
        "rancherUrl": "https://rancher.devops.dcentralab.com/verify-auth",
        "scope": "openid profile email groups"
      }' --token=${data.aws_eks_cluster_auth.eks-devops.token} --server=${module.eks-devops.cluster_endpoint} --certificate-authority="/tmp/ca.crt"
    EOT
  }
  depends_on = [
    helm_release.rancher
  ]
}
