output "lb_certificate_arn" {
  description = "ARN of ACM cert to use with Vault LB listener"
  value       = aws_acm_certificate.vault.arn
}

output "leader_tls_servername" {
  description = "Shared SAN that will be given to the Vault nodes configuration for use as leader_tls_servername"
  value       = var.shared_san
}

output "tls_cert_secrets_manager_arn" {
  description = "ARN of secrets_manager secret"
  value       = aws_secretsmanager_secret.tls.arn
}
