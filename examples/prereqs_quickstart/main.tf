provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./aws-vpc/"

  azs                  = var.azs
  common_tags          = var.tags
  resource_name_prefix = var.resource_name_prefix
}

module "secrets" {
  source = "./secrets/"

  resource_name_prefix = var.resource_name_prefix
}

