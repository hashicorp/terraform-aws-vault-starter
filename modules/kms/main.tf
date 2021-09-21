resource "aws_kms_key" "vault" {
  count                   = var.user_supplied_kms_key_arn != null ? 0 : 1
  deletion_window_in_days = var.kms_key_deletion_window
  description             = "AWS KMS Customer-managed key used for Vault auto-unseal and encryption"
  enable_key_rotation     = false
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"

  tags = merge(
    { Name = "${var.resource_name_prefix}-vault-key" },
    var.common_tags,
  )
}
