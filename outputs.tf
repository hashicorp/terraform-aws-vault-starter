output "vault_address" {
  value = module.vault_cluster.vault_address
}

output "vault_security_group" {
  value = module.vault_cluster.vault_security_group
}

output "vault_kms_key" {
  value = module.vault_cluster.aws_kms_key.vault.key_id
} 
  
output "vault_kms_alias" {
  value = module.vault_cluster.aws_kms_key_alias.vault.name
}    
