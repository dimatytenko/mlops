variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "admin"
}

variable "aws_region" {
  description = "AWS region for AWS provider (має відповідати регіону EKS)"
  type        = string
  default     = "eu-central-1"
}

variable "eks_state_bucket" {
  description = "S3 bucket з remote state EKS"
  type        = string
  default     = "mlops-tfstate-amgpetronass-eu"
}

variable "eks_state_key" {
  description = "S3 key для remote state EKS"
  type        = string
  default     = "eks/terraform.tfstate"
}

variable "eks_state_region" {
  description = "Регіон бакета з remote state EKS"
  type        = string
  default     = "eu-central-1"
}

variable "argocd_namespace" {
  description = "Namespace для Argo CD"
  type        = string
  default     = "infra-tools"
}

variable "argocd_chart_version" {
  description = "Версія Helm-чарту Argo CD"
  type        = string
  default     = "v7.7.5"
}

