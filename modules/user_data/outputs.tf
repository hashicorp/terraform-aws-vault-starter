output "vault_userdata_base64_encoded" {
  value = base64encode(local.vault_user_data)
}
