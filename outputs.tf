output "vault_address" {
  value = module.vault_cluster.vault_address
}

output "vault_security_group" {
  value = module.vault_cluster.vault_security_group
}

output "vault_kms_key" {
  value = module.vault_cluster.aws_kms_key.vault
}    
