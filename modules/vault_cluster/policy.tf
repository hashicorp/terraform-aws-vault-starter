resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = "${random_id.environment_name.hex}-vault"
  role        = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name_prefix        = "${random_id.environment_name.hex}-vault"
  assume_role_policy = data.aws_iam_policy_document.instance_role.json
}

data "aws_iam_policy_document" "instance_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "cluster_discovery_health" {
  name   = "${random_id.environment_name.hex}-vault-cluster_discovery_health"
  role   = aws_iam_role.instance_role.id
  policy = data.aws_iam_policy_document.cluster_discovery_health.json
}

data "aws_iam_policy_document" "cluster_discovery_health" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "autoscaling:CompleteLifecycleAction",
      "ec2:DescribeTags",
      "autoscaling:Describe*"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:Decrypt",
    ]

    resources = [
      "${aws_kms_key.vault.arn}",
    ]
  }
}

resource "aws_iam_policy" "create_tags" {
  name_prefix = "${random_id.environment_name.hex}-vault-create-tags-"
  path        = "/"
  description = "IAM policy for creating tags on instances"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "ec2:CreateTags",
            "Resource": "arn:aws:ec2:*:*:instance/*",
            "Condition": {
                "StringEquals": {
                    "ec2:InstanceProfile": "${aws_iam_instance_profile.instance_profile.arn}"
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "create_tags" {
  role       = aws_iam_role.instance_role.name
  policy_arn = aws_iam_policy.create_tags.arn
}

