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

# --- Main node group (t3.medium, ON_DEMAND) ---
variable "cpu_instance_type" {
  description = "Instance type for the main CPU node group"
  type        = string
  default     = "t3.medium"
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

# --- Additional tags ---
variable "tags" {
  description = "Common tags applied to all EKS resources"
  type        = map(string)
  default     = {}
}
