output "lb_certificate_arn" {
  description = "ARN of ACM cert to use with Vault LB listener"
  value       = module.secrets.lb_certificate_arn
}

output "leader_tls_servername" {
  description = "Shared SAN that will be given to the Vault nodes configuration for use as leader_tls_servername"
  value       = module.secrets.leader_tls_servername
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "secrets_manager_arn" {
  description = "ARN of secrets_manager secret"
  value       = module.secrets.secrets_manager_arn
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

