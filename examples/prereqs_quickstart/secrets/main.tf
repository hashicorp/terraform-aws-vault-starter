resource "aws_secretsmanager_secret" "tls" {
  name                    = "${var.resource_name_prefix}-tls-secret"
  description             = "contains TLS certs and private keys"
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "tls" {
  secret_id     = aws_secretsmanager_secret.tls.id
  secret_string = local.secret
}

