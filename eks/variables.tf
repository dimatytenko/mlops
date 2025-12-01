########################################
# eks/variables.tf (root-mode)
########################################

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "EKS version"
  type        = string
  default     = "1.29"
}

variable "region" {
  description = "AWS region for the EKS cluster"
  type        = string
  default     = "eu-central-1"
}

# --- Networking: passed from root (module.vpc.*) ---
variable "vpc_id" {
  description = "VPC ID where the EKS cluster is deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS worker nodes"
  type        = list(string)
}

# --- Main node group (Free Tier: t2.micro or t3.micro) ---
variable "cpu_instance_type" {
  description = "Instance type for the main CPU node group (Free Tier: t2.micro or t3.micro)"
  type        = string
  default     = "t3.micro"
}

variable "cpu_min_size" {
  description = "Minimum size of the main CPU node group"
  type        = number
  default     = 1
}

variable "cpu_desired_size" {
  description = "Desired size of the main CPU node group"
  type        = number
  default     = 2
}

variable "cpu_max_size" {
  description = "Maximum size of the main CPU node group"
  type        = number
  default     = 4
}

# --- GPU node group (Free Tier: t2.micro or t3.micro) ---
variable "gpu_instance_type" {
  description = "Instance type for the GPU node group (Free Tier: t2.micro or t3.micro)"
  type        = string
  default     = "t3.micro"
}

variable "gpu_capacity_type" {
  description = "Capacity type for GPU node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "SPOT"
}

variable "gpu_min_size" {
  description = "Minimum size of the GPU node group"
  type        = number
  default     = 0
}

variable "gpu_desired_size" {
  description = "Desired size of the GPU node group"
  type        = number
  default     = 0
}

variable "gpu_max_size" {
  description = "Maximum size of the GPU node group"
  type        = number
  default     = 3
}

variable "gpu_taints" {
  description = "Taints for GPU node group (optional)"
  type = list(object({
    key    = string
    value  = optional(string)
    effect = string
  }))
  default = []
}

# --- Additional tags ---
variable "tags" {
  description = "Common tags applied to all EKS resources"
  type        = map(string)
  default     = {}
}
