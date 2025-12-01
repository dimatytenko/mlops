########################################
# eks/main.tf (root-mode, minimal)
########################################

# Get VPC data from remote state (if VPC was created separately)
# Fallback to variables if remote state is not available
data "terraform_remote_state" "vpc" {
  backend = "local"
  
  config = {
    path = "${path.root}/vpc/terraform.tfstate"
  }
}

# Use remote state if available, otherwise use variables
locals {
  vpc_id             = try(data.terraform_remote_state.vpc.outputs.vpc_id, var.vpc_id)
  private_subnet_ids = try(data.terraform_remote_state.vpc.outputs.private_subnet_ids, var.private_subnet_ids)
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

  # Networking (from remote state or variables)
  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnet_ids

  # Node groups: CPU and GPU (for Free Tier using t3.micro, but labeled for GPU tasks)
  eks_managed_node_groups = {
    cpu = {
      name           = "cpu-ng"
      instance_types = [var.cpu_instance_type]  # Free Tier: t3.micro or t2.micro
      capacity_type  = "ON_DEMAND"

      min_size     = var.cpu_min_size
      desired_size = var.cpu_desired_size
      max_size     = var.cpu_max_size

      labels = {
        workload-type = "cpu"
        node-type     = "cpu"
      }
    }

    gpu = {
      name           = "gpu-ng"
      instance_types = [var.gpu_instance_type]  # Free Tier: t3.micro or t2.micro
      capacity_type  = var.gpu_capacity_type

      min_size     = var.gpu_min_size
      desired_size = var.gpu_desired_size
      max_size     = var.gpu_max_size

      labels = {
        workload-type = "gpu"
        node-type     = "gpu"
      }

      taints = var.gpu_taints
    }
  }

  tags = var.tags
}
