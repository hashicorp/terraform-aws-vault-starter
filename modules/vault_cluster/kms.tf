resource "aws_kms_key" "vault" {
  description             = "${random_id.environment_name.hex} - Vault Unseal Key"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "vault" {
  name          = "alias/vault/${random_id.environment_name.hex}"
  target_key_id = aws_kms_key.vault.key_id
}
