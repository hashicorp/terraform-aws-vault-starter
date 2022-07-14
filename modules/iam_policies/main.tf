resource "aws_iam_role_policy" "cloud_auto_join" {
  name = format("%s-vault-auto-join", var.resource_name_prefix)
  role = var.iam_role_arn

  policy = data.aws_iam_policy_document.cloud_auto_join.json
}

data "aws_iam_policy_document" "cloud_auto_join" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "auto_unseal" {
  name   = format("%s-vault-auto-unseal", var.resource_name_prefix)
  role   = var.iam_role_arn
  policy = data.aws_iam_policy_document.auto_unseal.json
}

data "aws_iam_policy_document" "auto_unseal" {
  statement {
    effect = "Allow"

    actions = [
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = [
      var.kms_key_arn_backend,
      var.kms_key_arn_seal
    ]
  }
}

resource "aws_iam_role_policy" "session_manager" {
  name   = format("%s-vault-ssm", var.resource_name_prefix)
  role   = var.iam_role_arn
  policy = data.aws_iam_policy_document.session_manager.json
}

data "aws_iam_policy_document" "session_manager" {
  statement {
    effect = "Allow"

    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "secrets_manager" {
  name   = format("%s-vault-secrets-manager", var.resource_name_prefix)
  role   = var.iam_role_arn
  policy = data.aws_iam_policy_document.secrets_manager.json
}

data "aws_iam_policy_document" "secrets_manager" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = var.secret_manager_arns
  }
}
