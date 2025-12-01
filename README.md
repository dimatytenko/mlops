# AWS EKS Infrastructure with Terraform

This project creates **VPC** and **EKS cluster** in AWS using Terraform with modular structure.
The infrastructure uses official Terraform modules:  
- **terraform-aws-modules/vpc/aws** for VPC creation
- **terraform-aws-modules/eks/aws** for EKS cluster

## Features

- VPC with public and private subnets across multiple availability zones
- EKS cluster with **two node groups** (CPU and GPU):
  - `cpu-ng` → `t3.micro` (Free Tier), **ON_DEMAND**, labeled for CPU workloads
  - `gpu-ng` → `t3.micro` (Free Tier), **SPOT**, labeled for GPU workloads
- **IRSA** enabled for future integration of IAM Roles for Service Accounts
- EKS module connects to VPC using `terraform_remote_state` data source
- Provider configuration only in root module (modules inherit it)

---

## 📂 Project structure
    ```
    .
    ├── main.tf              # Root module: connects VPC and EKS
    ├── variables.tf         # Global variables
    ├── outputs.tf           # Key outputs (VPC + EKS + kubeconfig)
    ├── terraform.tf         # Terraform version requirements
    ├── backend.tf            # Backend configuration
    ├── vpc/                 # VPC module
    │   ├── main.tf          # VPC module definition
    │   ├── variables.tf     # VPC input parameters
    │   ├── outputs.tf       # VPC outputs (vpc_id, subnets)
    │   ├── terraform.tf     # Terraform version
    │   └── backend.tf       # Backend configuration
    ├── eks/                 # EKS module
    │   ├── main.tf          # EKS module with terraform_remote_state
    │   ├── variables.tf     # EKS input parameters
    │   ├── outputs.tf       # EKS outputs (cluster info)
    │   ├── terraform.tf     # Terraform version
    │   └── backend.tf       # Backend configuration
    └── README.md            # This file

---

## Run

1. Preparation

- Install [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.5.0).  
- Configure AWS CLI with permissions to create resources:  
   ```bash
   aws configure
   ```

2. Initialization

    ```bash
    terraform init -upgrade
    ```

3. View the plan

    ```bash
    terraform plan
    ```

4. Create infrastructure

    ```bash
    terraform apply -auto-approve
    ```

5. Check that the cluster is created:

    ```bash
    # Get the cluster name from outputs
    terraform output kubeconfig_update_command
    
    # Or manually (replace with your region and cluster name):
    aws eks --region eu-central-1 update-kubeconfig --name goit-eks-cluster
    kubectl get nodes

6. Delete infrastructure

    ```bash
    terraform destroy -auto-approve
    ```

7. Delete directories and files recursively, without confirmation  

    ```bash
    rm -rf .terraform .terraform.lock.hcl
    ```    

## Architecture

- **VPC Module**: Creates VPC with public and private subnets using `terraform-aws-modules/vpc/aws`
- **EKS Module**: Creates EKS cluster with 2 node groups (CPU and GPU) using `terraform-aws-modules/eks/aws`
  - Connects to VPC via `data.terraform_remote_state` (with fallback to variables)
  - Both node groups use Free Tier instance types (`t3.micro`)
  - Node groups have labels for workload type (cpu/gpu)
- **Root Module**: Orchestrates both modules and provides unified interface

## Notes

- The cost of the infrastructure depends on the chosen instances
- GPU node group starts with 0 nodes (desired_size = 0) by default
- IRSA is already enabled, you can add IAM Roles for Service Accounts
- Instance types are set to `t3.micro` (Free Tier compatible)
- Node groups are labeled: `workload-type=cpu` and `workload-type=gpu` for easy pod scheduling
- Default region: `eu-central-1`
- Default cluster name: `goit-eks-cluster`