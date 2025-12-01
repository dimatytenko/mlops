########################################
# eks/main.tf (root-mode, minimal)
########################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.63"
    }
  }
}

provider "aws" {
  region = var.region
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.0"

  # Cluster
  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  enable_irsa                     = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false
  # Give the creator of the cluster (your current AWS IAM principal) cluster-admin permissions   
  enable_cluster_creator_admin_permissions = true

  # Networking (passed from root)
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Node groups: main ON_DEMAND + cheaper SPOT
  eks_managed_node_groups = {
    main = {
      name           = "main-ng"
      instance_types = [var.cpu_instance_type]  # e.g., t3.medium
      capacity_type  = "ON_DEMAND"

      min_size     = var.cpu_min_size
      desired_size = var.cpu_desired_size
      max_size     = var.cpu_max_size
    }

    cheap = {
      name           = "cheap-ng"
      instance_types = ["t3.micro"]
      capacity_type  = "SPOT"

      min_size     = 0
      desired_size = 0
      max_size     = 3
    }
  }

  tags = var.tags
}
