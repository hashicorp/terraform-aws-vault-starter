module "vault_cluster" {
  source = "./modules/vault_cluster"

  vpc_id                       = var.vpc_id
  vault_version                = var.vault_version
  owner                        = var.owner
  name_prefix                  = var.name_prefix
  key_name                     = var.key_name
  instance_type                = var.instance_type
  vault_nodes                  = var.vault_nodes
  vault_cluster_version        = var.vault_cluster_version
  nat_gateway_subnet_cidr      = var.nat_gateway_subnet_cidr
  lambda_primary_subnet_cidr   = var.lambda_primary_subnet_cidr
  lambda_secondary_subnet_cidr = var.lambda_secondary_subnet_cidr
}
