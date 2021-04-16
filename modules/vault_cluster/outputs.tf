output "vault_uri" {
  value = "http://${aws_lb.vault.dns_name}:8200"
}

output "vault_address" {
  value = aws_lb.vault.dns_name
}

output "vault_kms_key" {
  vaule = aws_kms_key.vault.key_id
}

output "vault_kms_alias" {
  vaule = aws_kms_key_alias.vault.name
}


// Can be used to add additional SG rules to Vault instances.
output "vault_security_group" {
  value = aws_security_group.vault.id
}
