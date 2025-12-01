########################################
# vpc/main.tf
########################################

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # How many AZs to take
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Private /20: 0..N-1 → 10.42.0.0/20, 10.42.16.0/20, 10.42.32.0/20 ...
  private_netnums = range(length(local.azs))
  private_subnets = [for i in local.private_netnums : cidrsubnet(var.cidr, 4, i)]

  # Public /24: EXCLUDED FAR, to not overlap with private
  # For /16 base CIDR safely take start ≥ 200 → 10.42.200.0/24, 201.0/24, 202.0/24
  public_start   = 200
  public_netnums = [for i in range(length(local.azs)) : i + local.public_start]
  public_subnets = [for i in local.public_netnums : cidrsubnet(var.cidr, 8, i)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = var.enable_nat_gw
  single_nat_gateway = var.single_nat_gw

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    Tier                      = "public"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    Tier                               = "private"
  }

  tags = merge(var.tags, { Module = "vpc" })
}
