########################################
# eks/outputs.tf
########################################

# Basic cluster identifiers
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

# --- IRSA outputs (available only if enable_irsa = true) ---
output "oidc_provider_arn" {
  description = "OIDC provider ARN for the EKS cluster (used by IRSA)"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL for the EKS cluster (used by IRSA)"
  value       = module.eks.oidc_provider
}

# Security Group cluster (control plane)
output "cluster_security_group_id" {
  description = "Security Group ID associated with the EKS control plane"
  value       = module.eks.cluster_security_group_id
}
