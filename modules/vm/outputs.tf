output "launch_template_id" {
  description = "ID of launch template for Vault autoscaling group"
  value       = aws_launch_template.vault.id
}

output "vault_sg_id" {
  description = "Security group ID of Vault cluster"
  value       = aws_security_group.vault.id
}
