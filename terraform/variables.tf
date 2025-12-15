variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for created resources"
  type        = string
  default     = "mlops-train-automation"
}
