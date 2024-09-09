module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = var.vpc_name
  cidr = "10.0.0.0/16"

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
  }
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    eks_nodes = {
      ami_type      = "AL2023_x86_64_STANDARD"
      instance_type = ["t3.medium"]

      desired_capacity = 3
      max_capacity     = 5
      min_capacity     = 3
    }
  }
  enable_cluster_creator_admin_permissions = true
}