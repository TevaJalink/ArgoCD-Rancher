terraform {
  backend "s3" {
    bucket = "k8s-management-system"
    key    = "terraform/terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.65.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.15.0"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks-devops.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks-devops.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.eks-devops.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks-devops.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks-devops.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.eks-devops.token
  }
}

data "aws_eks_cluster_auth" "eks-devops" {
  name = module.eks-devops.cluster_name
}

provider "rancher2" {
  api_url   = "https://${var.rancher_hostname}/v3"
  token_key = random_password.rancher_user.result
}