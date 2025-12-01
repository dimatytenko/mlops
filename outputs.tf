########################################
# root/outputs.tf
########################################

# --- VPC summary ---
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_private_subnets" {
  description = "Private subnets"
  value       = module.vpc.private_subnet_ids
}

output "vpc_public_subnets" {
  description = "Public subnets"
  value       = module.vpc.public_subnet_ids
}

# --- EKS summary ---
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_region" {
  description = "AWS region of EKS cluster"
  value       = var.region
}

output "eks_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

# --- Ready-to-use kubeconfig command ---
output "kubeconfig_update_command" {
  description = "Run this to configure kubectl access"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
}


output "kubectl_get_nodes_command" {
  description = "Run this to verify the cluster nodes"
  value       = "kubectl get nodes"
}
