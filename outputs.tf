output "vault_address" {
  value = module.vault_cluster.vault_address
}

output "vault_security_group" {
  value = module.vault_cluster.vault_security_group
}

output "vault_kms_key" {
  value = module.vault_cluster.vault_kms_key
} 
  
output "vault_kms_alias" {
  value = module.vault_cluster.vault_kms_alias
}    

output "vault_lb_arn" {
  value = module.vault_cluster.vault_lb_arn
}    

output "vault_vault_tg_arn" {
  value = module.vault_cluster.vault_tg_arn
}    
