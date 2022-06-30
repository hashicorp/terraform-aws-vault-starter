output "kms_key_arn" {
  value = module.kms.kms_key_arn
}

output "launch_template_id" {
  value = module.vm.launch_template_id
}

output "vault_lb_dns_name" {
  description = "DNS name of Vault load balancer"
  value       = module.loadbalancer.vault_lb_dns_name
}

output "vault_lb_zone_id" {
  description = "Zone ID of Vault load balancer"
  value       = module.loadbalancer.vault_lb_zone_id
}

output "vault_lb_arn" {
  description = "ARN of Vault load balancer"
  value       = module.loadbalancer.vault_lb_arn
}

output "vault_target_group_arn" {
  description = "Target group ARN to register Vault nodes with"
  value       = module.loadbalancer.vault_target_group_arn
}

output "vault_sg_id" {
  description = "Security group ID of Vault cluster"
  value       = module.vm.vault_sg_id
}
