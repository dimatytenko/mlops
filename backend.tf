# Optional: local backend for the root state (nothing critical is saved here)
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
