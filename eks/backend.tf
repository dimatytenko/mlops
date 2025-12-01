terraform {
  backend "local" {
    path = "eks/terraform.tfstate"
  }
}