output "vault_seal_unseal_kms_key_arn" {
  value = aws_kms_key.vault_seal_mechanism.arn
}

output "backend_kms_key_arn" {
  value = aws_kms_key.backend.arn
}
