# AWS EKS Infrastructure with Terraform

This project creates **VPC** and **EKS cluster** in AWS using Terraform.  
The infrastructure is minimalistic:  
- VPC with public and private subnets  
- EKS cluster with **two node groups**:
  - `main-ng` → `t3.medium`, **ON_DEMAND**
  - `cheap-ng` → `t3.micro`, **SPOT**  
- **IRSA** enabled for future integration of IAM Roles for Service Accounts  

---

## 📂 Project structure
    ```
    .
    ├── vpc/ # module for creating VPC 
    ├── eks/ # module for creating EKS
    ├── root/main.tf # connects VPC and EKS together
    ├── root/variables.tf # global variables
    ├── root/outputs.tf # key outputs (VPC + EKS + kubeconfig)
    └── README.md # this file

---

## Run

1. Preparation

- Install [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.5.0).  
- Configure AWS CLI with permissions to create resources:  
   ```
   aws configure

2. Initialization

    ```
    terraform init -upgrade

3. View the plan

    ```
    terraform plan

4. Create infrastructure

    ```
    terraform apply -auto-approve

5. Check that the cluster is created:

    ```
    aws eks --region <region> update-kubeconfig --name <your-cluster-name>`
    kubectl get nodes

6. Delete infrastructure

    ```
    terraform destroy -auto-approve

7. Delete directories and files recursively, without confirmation  

    ```
    rm -rf .terraform .terraform.lock.hcl    

Notes:

The cost of the infrastructure depends on the chosen instances.

For cheap node group to start with 0 nodes.

IRSA is already enabled, you can add IAM Roles for Service Accounts.