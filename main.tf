########################################
# root/main.tf
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

# 1 First create VPC
module "vpc" {
  source = "./vpc"

  name            = var.vpc_name
  cidr            = var.vpc_cidr
  az_count        = var.vpc_az_count
  enable_nat_gw   = var.enable_nat_gw
  single_nat_gw   = var.single_nat_gw
  region          = var.region
  tags            = var.tags
}

# 2 Then create EKS, directly connecting the outputs from VPC
#    (remote_state here is not needed, because we already have it in the root)
module "eks" {
  source = "./eks"

  cluster_name     = var.cluster_name
  cluster_version  = var.cluster_version
  region           = var.region

  # disable remote_state and pass the values from module.vpc

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  cpu_instance_type = var.cpu_instance_type
  cpu_min_size      = var.cpu_min_size
  cpu_desired_size  = var.cpu_desired_size
  cpu_max_size      = var.cpu_max_size

  gpu_instance_type = var.gpu_instance_type
  gpu_capacity_type = var.gpu_capacity_type
  gpu_min_size      = var.gpu_min_size
  gpu_desired_size  = var.gpu_desired_size
  gpu_max_size      = var.gpu_max_size

  tags = var.tags
}
