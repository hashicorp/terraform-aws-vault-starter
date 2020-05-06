resource "aws_secretsmanager_secret" "vault" {
  name_prefix             = "${random_id.environment_name.hex}-"
  description             = "contains root token and recovery keys"
  recovery_window_in_days = 0
}

resource "aws_iam_role" "vault_join_init_lambda" {
  name_prefix = "${random_id.environment_name.hex}-vault-init-"
  path        = "/service-role/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs_join_init" {
  role       = aws_iam_role.vault_join_init_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}


resource "aws_iam_policy" "lambda_put_secrets" {
  name_prefix = "${random_id.environment_name.hex}-vault-lambda-init-secrets-manager-"
  path        = "/"
  description = "IAM policy for putting secrets into AWS Secrets Manager"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:UpdateSecretVersionStage",
                "secretsmanager:UpdateSecret"
            ],
            "Resource": "${aws_secretsmanager_secret.vault.arn}"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_put_secrets" {
  role       = aws_iam_role.vault_join_init_lambda.name
  policy_arn = aws_iam_policy.lambda_put_secrets.arn
}

resource "aws_iam_policy" "lambda_describe_ec2" {
  name_prefix = "${random_id.environment_name.hex}-vault-lambda-describe-ec2-"
  path        = "/"
  description = "IAM policy for describing ec2 instances"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "elasticloadbalancing:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:Describe*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "autoscaling:Describe*",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_describe_ec2" {
  role       = aws_iam_role.vault_join_init_lambda.name
  policy_arn = aws_iam_policy.lambda_describe_ec2.arn
}

resource "aws_iam_policy" "lambda_describe_autoscaling" {
  name_prefix = "${random_id.environment_name.hex}-vault-lambda-describe-autoscaling-"
  path        = "/"
  description = "IAM policy for describing autoscaling groups"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "autoscaling:Describe*",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_describe_autoscaling" {
  role       = aws_iam_role.vault_join_init_lambda.name
  policy_arn = aws_iam_policy.lambda_describe_autoscaling.arn
}

resource "aws_iam_role_policy_attachment" "lambda_init_manage_net" {
  role       = aws_iam_role.vault_join_init_lambda.name
  policy_arn = aws_iam_policy.lambda_manage_network_interfaces.arn
}

resource "aws_lambda_function" "vault_join_init" {
  function_name = "${random_id.environment_name.hex}-vault-init"
  filename      = "${path.module}/lambda_functions/vault_init/main.zip"
  role          = aws_iam_role.vault_join_init_lambda.arn
  handler       = "main"

  vpc_config {
    subnet_ids         = [aws_subnet.lambda_primary.id, aws_subnet.lambda_secondary.id]
    security_group_ids = [aws_security_group.vault.id]
  }

  runtime = "go1.x"
  timeout = 15

  environment {
    variables = {
      awsRegion = data.aws_region.current.name
      secretID  = aws_secretsmanager_secret.vault.name
    }
  }
}

data "aws_lambda_invocation" "vault_join_init" {
  function_name = "${aws_lambda_function.vault_join_init.function_name}"

  input = <<JSON
{
  "resources": [
    "auto-scaling-group-arn"
  ],
  "detail": { 
    "AutoScalingGroupName": "${aws_autoscaling_group.vault.name}" 
  } 
}
JSON

  depends_on = [
    aws_subnet.lambda_primary,
    aws_subnet.lambda_secondary
  ]
}
