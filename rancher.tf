data "aws_caller_identity" "current" {}

resource "aws_iam_role" "rds_access_role" {
  name = "rancher-rds-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.eks-devops.cluster_oidc_issuer_url}"
        }
        Condition = {
          "StringEquals" = {
            "${module.eks-devops.cluster_oidc_issuer_url}:sub" = "system:serviceaccount:cattle-system:rancher-service-account"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "rds_access_policy" {
  role = aws_iam_role.rds_access_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds-db:connect"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.RDS-Instance.identifier}/rancherdbuser"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_policy_attachment" {
  role       = aws_iam_role.rds_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "kubernetes_service_account" "rancher_sa" {
  metadata {
    name      = "rancher-service-account"
    namespace = "cattle-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.rds_access_role.arn
    }
  }
}

resource "random_password" "rancher_user" {
  length  = 16
  special = false
  numeric = true
  upper   = true
  lower   = true
}

resource "helm_release" "rancher" {
  name             = "rancher"
  namespace        = "cattle-system"
  repository       = "https://releases.rancher.com/server-charts/stable"
  chart            = "rancher"
  version          = "2.9.1"
  create_namespace = true

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

  # rke remote backend with aws rds
  set {
    name  = "externalDatabase.type"
    value = "postgresql"
  }

  set {
    name  = "externalDatabase.postgresql.host"
    value = aws_db_instance.RDS-Instance.endpoint
  }

  set {
    name  = "externalDatabase.postgresql.database"
    value = var.db_name
  }

  set {
    name  = "externalDatabase.postgresql.port"
    value = "5432"
  }

  set {
    name  = "externalDatabase.postgresql.username"
    value = "rancherdbuser"
  }

  set {
    name  = "externalDatabase.postgresql.iam"
    value = "true"
  }

  set {
    name  = "serviceAccountName"
    value = "rancher-service-account"
  }

  #oidc intergration with okta
  set {
    name  = "auth.provider"
    value = "oidc"
  }

  set {
    name  = "auth.oidc.clientId"
    value = var.okta_client_id_rancher
  }

  set {
    name  = "auth.oidc.clientSecret"
    value = var.okta_client_secret_rancher
  }

  set {
    name  = "auth.oidc.issuer"
    value = var.okta_issuer_url
  }

  set {
    name  = "auth.oidc.redirectUri"
    value = "https://${var.rancher_hostname}/v1-auth/callback"
  }

  set {
    name  = "auth.oidc.scopes"
    value = "openid,email,profile,groups"
  }

  set {
    name  = "auth.rbac.admin_group"
    value = var.devops_admin_group
  }
}

data "kubernetes_service" "rancher_server" {
  metadata {
    name      = "rancher"
    namespace = "cattle-system"
  }
}