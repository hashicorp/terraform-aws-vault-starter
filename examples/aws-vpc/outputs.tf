output "private_subnet_tags" {
  description = "tags of private subnets that will be used to filter them while installing Vault"
  value       = var.private_subnet_tags
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}
