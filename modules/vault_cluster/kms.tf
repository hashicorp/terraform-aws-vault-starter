resource "aws_kms_key" "vault" {
  description             = "${random_id.environment_name.hex} - Vault Unseal Key"
  deletion_window_in_days = 10
}