
# data "terraform_remote_state" "eks" {
#   backend = "s3"
#   config = {
#     bucket = "mlops-tfstate-amgpetronass-eu"
#     key    = "eks-vpc-cluster/terraform.tfstate"
#     region = "eu-central-1"
#   }
# }


# Доступ до існуючого кластера EKS
data "aws_eks_cluster" "cluster" {
  name = "goit-eks"
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.aws_eks_cluster.cluster.name
}






