output "vault_address" {
  value = "http://${aws_lb.vault.dns_name}:8200"
}

// Can be used to add additional SG rules to Vault instances.
output "vault_security_group" {
  value = aws_security_group.vault.id
}
