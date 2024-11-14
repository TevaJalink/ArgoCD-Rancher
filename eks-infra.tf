module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_availability_zones
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    "Name"                                      = var.vpc_name
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

module "eks-devops" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.0"

  cluster_name                   = var.cluster_name
  cluster_version                = "1.30"
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
    aws-ebs-csi-driver     = {}
  }
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    eks_nodes = {
      ami_type      = "AL2023_x86_64_STANDARD"
      instance_type = ["t3.medium"]

      desired_size = 3
      max_size     = 5
      min_size     = 3
      iam_role_additional_policies = {
        policy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true
}

module "aws-auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "20.24.0"

  manage_aws_auth_configmap = true
  aws_auth_users = [
    {
      userarn  = module.eks-devops.cluster_iam_role_arn
      username = "eks-iam-role"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::048695807141:role/Terraform-EKS-Cluster"
      username = "eks-iam-role"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::048695807141:user/teva@keyper"
      username = "teva"
      groups   = ["system:masters"]
    }
  ]
}

resource "helm_release" "metrics-server" {
  name = "metrics-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
}

resource "aws_route53_zone" "devops_subdomain" {
  name = "devops.dcentralab.com"
}

resource "aws_vpc_security_group_ingress_rule" "http_between_nodes" {
  security_group_id = module.eks-devops.node_security_group_id

  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = module.eks-devops.node_security_group_id
  description                  = "Allows HTTP traffic between nodes"
}

resource "aws_vpc_security_group_ingress_rule" "https_between_nodes" {
  security_group_id = module.eks-devops.node_security_group_id

  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = module.eks-devops.node_security_group_id
  description                  = "Allows HTTPS traffic between nodes"
}

resource "aws_vpc_security_group_ingress_rule" "open_port_444_between_nodes" {
  security_group_id = module.eks-devops.node_security_group_id

  ip_protocol                  = "tcp"
  from_port                    = 444
  to_port                      = 444
  referenced_security_group_id = module.eks-devops.node_security_group_id
  description                  = "Allows traffic on port 444 between nodes"
}

resource "aws_vpc_security_group_ingress_rule" "http_from_node_to_control" {
  security_group_id = module.eks-devops.cluster_security_group_id

  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = module.eks-devops.node_security_group_id
  description                  = "Allows HTTP traffic from nodes to control plane"
}

resource "aws_vpc_security_group_ingress_rule" "https_from_node_to_control" {
  security_group_id = module.eks-devops.cluster_security_group_id

  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = module.eks-devops.node_security_group_id
  description                  = "Allows HTTPS traffic from nodes to control plane"
}