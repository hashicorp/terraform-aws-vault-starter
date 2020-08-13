# names required TF version
terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "2.70.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "2.3.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.1.2"
    }
  }
}
