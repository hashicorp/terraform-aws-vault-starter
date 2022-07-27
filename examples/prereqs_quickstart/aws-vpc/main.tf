module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  version                = "3.0.0"
  name                   = "${var.resource_name_prefix}-vault"
  cidr                   = var.vpc_cidr
  azs                    = var.azs
  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = true
  private_subnets        = var.private_subnet_cidrs
  public_subnets         = var.public_subnet_cidrs

  tags = var.common_tags
}

