variable "project_name" {
  description = "Base name/prefix for resources (used in VPC/EKS names)"
  type        = string
  default     = "goit-eks"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

# ------- VPC -------
variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "goit-eks-vpc"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.42.0.0/16"   
}


variable "vpc_az_count" {
  description = "How many Availability Zones to use"
  type        = number
  default     = 3
}

variable "enable_nat_gw" {
  description = "Create NAT Gateway(s) for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gw" {
  description = "Use a single NAT GW (cost-saving). If false, one per AZ."
  type        = bool
  default     = true
}

# ------- EKS -------
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "goit-eks-cluster"
}

variable "cluster_version" {
  description = "EKS version"
  type        = string
  default     = "1.29"
}

variable "cpu_instance_type" {
  description = "Instance type for CPU node group"
  type        = string
  default     = "t3.small"
}

variable "cpu_min_size" {
  description = "Min size of the CPU node group"
  type        = number
  default     = 1
}

variable "cpu_desired_size" {
  description = "Desired size of the CPU node group"
  type        = number
  default     = 2
}

variable "cpu_max_size" {
  description = "Max size of the CPU node group"
  type        = number
  default     = 4
}

# ------- Tags (optional common) -------
variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {
    Project = "goit-eks"
    Owner   = "Amgpetronass"
  }
}
