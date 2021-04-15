module "vault_cluster" {
  source = "./modules/vault_cluster"

  allowed_inbound_cidrs        = var.allowed_inbound_cidrs
  vpc_id                       = var.vpc_id
  vault_version                = var.vault_version
  owner                        = var.owner
  name_prefix                  = var.name_prefix
  elb_internal                 = var.elb_internal
  key_name                     = var.key_name
  instance_type                = var.instance_type
  vault_nodes                  = var.vault_nodes
  vault_cluster_version        = var.vault_cluster_version
  lb_subnets                   = var.lb_subnets
  nat_gateway_subnet_cidr      = var.nat_gateway_subnet_cidr
  lambda_primary_subnet_cidr   = var.lambda_primary_subnet_cidr
  lambda_secondary_subnet_cidr = var.lambda_secondary_subnet_cidr
}
