resource "aws_kms_key" "vault_seal_mechanism" {
  deletion_window_in_days = var.kms_key_deletion_window
  description             = format("%s encryption key used for Vault auto-unseal and encryption.", var.resource_name_prefix)
  enable_key_rotation     = false
  is_enabled              = true
  policy                  = var.custom_kms_seal_unseal_policy == null ? one(data.aws_iam_policy_document.kms_policy[*].json) : var.custom_kms_seal_unseal_policy
  key_usage               = "ENCRYPT_DECRYPT"

  tags = merge(
    { Name = format("%s-vault-seal-key", var.resource_name_prefix) },
    var.common_tags,
  )
}

resource "aws_kms_alias" "vault_seal_mechanism" {
  name          = format("alias/%s-vault-seal-key", var.resource_name_prefix)
  target_key_id = aws_kms_key.vault_seal_mechanism.key_id
}

resource "aws_kms_key" "backend" {
  description             = format("%s encryption key for AWS backend infrastructure.", var.resource_name_prefix)
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = false
  is_enabled              = true
  policy                  = var.custom_kms_backend_policy == null ? one(data.aws_iam_policy_document.kms_policy[*].json) : var.custom_kms_backend_policy
  key_usage               = "ENCRYPT_DECRYPT"

  tags = merge(
    { Name = format("%s-vault-backend-key", var.resource_name_prefix) },
    var.common_tags,
  )
}

resource "aws_kms_alias" "backend" {
  name          = format("alias/%s-vault-backend-key", var.resource_name_prefix)
  target_key_id = aws_kms_key.backend.key_id
}

data "aws_iam_policy_document" "kms_policy" {
  count = length(compact([var.custom_kms_seal_unseal_policy, var.custom_kms_backend_policy])) < 1 ? 1 : 0

  statement {
    sid     = "Enable Administrator access"
    actions = ["kms:*"]
    resources = [
      "*"
    ]
    principals {
      type        = var.kms_key_administrators != null ? lookup(var.kms_key_administrators, "type") : "AWS"
      identifiers = var.kms_key_administrators != null ? lookup(var.kms_key_administrators, "identifiers") : ["arn:aws:iam::${var.account_id}:root"]
    }
  }

  statement {
    sid = "Allow autoscaling service role"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    principals {
      type        = "AWS"
      identifiers = [var.autoscaling_service_linked_role_arn]
    }

    resources = ["*"]
  }

  statement {
    sid = "Allow autoscaling attachment of persistent resources"
    actions = [
      "kms:CreateGrant"
    ]

    principals {
      type        = "AWS"
      identifiers = [var.autoscaling_service_linked_role_arn]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"

      values = [true]
    }

    resources = ["*"]
  }

  statement {
    sid = "Allow EC2 KMS Use"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*"
    ]

    principals {
      type        = "AWS"
      identifiers = [var.instance_role_arn]
    }

    resources = ["*"]
  }
}
