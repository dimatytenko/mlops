
#terraform {
 # backend "s3" {
  #  bucket  = "mlops-tfstate-amgpetronass-eu"
   # key     = "eks-vpc-cluster/terraform.tfstate"
    #region  = "eu-central-1"
    #profile = "admin"
 # }
#}

terraform {
  backend "local" {
    path = "terraform-argocd.tfstate"
  }
}
