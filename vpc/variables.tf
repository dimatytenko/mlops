variable "name" {
  type        = string
  description = "VPC name (used as a name prefix for resources)"
  validation {
    condition     = length(var.name) > 0 && can(regex("^[a-zA-Z0-9-]+$", var.name))
    error_message = "name must be non-empty and contain only letters, numbers, and hyphens."
  }
}

variable "cidr" {
  type        = string
  description = "VPC CIDR block (use a private RFC1918 range, e.g. 10.42.0.0/16)"
  validation {
    condition     = can(cidrnetmask(var.cidr))
    error_message = "cidr must be a valid CIDR, e.g. 10.42.0.0/16."
  }
}

variable "az_count" {
  type        = number
  description = "How many Availability Zones to use (slice of available AZs)"
  default     = 3
  validation {
    condition     = var.az_count >= 1 && var.az_count <= 6
    error_message = "az_count must be between 1 and 6."
  }
}

variable "enable_nat_gw" {
  type        = bool
  description = "Whether to create NAT Gateway(s) for private subnets to reach the Internet"
  default     = true
}

variable "single_nat_gw" {
  type        = bool
  description = "If true, create a single NAT Gateway (cost-saving). If false, one per AZ."
  default     = true
  validation {
    condition     = (var.single_nat_gw == false) || (var.enable_nat_gw == true)
    error_message = "single_nat_gw=true requires enable_nat_gw=true."
  }
}

variable "region" {
  type        = string
  description = "AWS region for this VPC (e.g., eu-central-1)"
  default     = "eu-central-1"  
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
  default     = {}
}
