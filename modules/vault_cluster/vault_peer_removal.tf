resource "aws_autoscaling_lifecycle_hook" "vault_terminate" {
  name                   = "${random_id.environment_name.hex}-vault-remove-peer"
  autoscaling_group_name = aws_autoscaling_group.vault.name
  default_result         = "CONTINUE"
  heartbeat_timeout      = 3600
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}

resource "aws_cloudwatch_event_rule" "vault_remove_peer" {
  name_prefix   = "${random_id.environment_name.hex}-vault-remove-peer-"
  event_pattern = <<EOF
{
  "source": [
    "aws.autoscaling"
  ],
  "detail-type": [
    "EC2 Instance-terminate Lifecycle Action"
  ],
  "detail": {
    "AutoScalingGroupName": [
        "${aws_autoscaling_group.vault.name}"
    ]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "vault_remove_peer" {
  rule = aws_cloudwatch_event_rule.vault_remove_peer.name
  arn  = aws_lambda_function.vault_remove_peer.arn
}

resource "aws_iam_role" "vault_remove_peer_lambda" {
  name_prefix = "${random_id.environment_name.hex}-vault-remove-"
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

resource "aws_iam_policy" "lambda_logging" {
  name_prefix = "${random_id.environment_name.hex}-vault-lambda-logging-"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.vault_remove_peer_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}


resource "aws_iam_policy" "lambda_get_secrets" {
  name        = "${random_id.environment_name.hex}-vault-lambda-peer-removal"
  path        = "/"
  description = "IAM policy for getting secrets from AWS Secrets Manager"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "${aws_secretsmanager_secret.vault.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_get_secrets" {
  role       = aws_iam_role.vault_remove_peer_lambda.name
  policy_arn = aws_iam_policy.lambda_get_secrets.arn
}

resource "aws_iam_policy" "lambda_complete_lifecycle" {
  name        = "${random_id.environment_name.hex}-vault-lambda-lifecycle"
  path        = "/"
  description = "IAM policy for completing lifecycle actions"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "autoscaling:CompleteLifecycleAction",
            "Resource": "${aws_autoscaling_group.vault.arn}"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_complete_lifecycle" {
  role       = aws_iam_role.vault_remove_peer_lambda.name
  policy_arn = aws_iam_policy.lambda_complete_lifecycle.arn
}

resource "aws_iam_role_policy_attachment" "lambda_removal_manage_net" {
  role       = aws_iam_role.vault_remove_peer_lambda.name
  policy_arn = aws_iam_policy.lambda_manage_network_interfaces.arn
}

resource "aws_iam_role_policy_attachment" "lambda_removal_describe_ec2" {
  role       = aws_iam_role.vault_remove_peer_lambda.name
  policy_arn = aws_iam_policy.lambda_describe_ec2.arn
}

resource "aws_iam_role_policy_attachment" "lambda_removal_describe_autoscaling" {
  role       = aws_iam_role.vault_remove_peer_lambda.name
  policy_arn = aws_iam_policy.lambda_describe_autoscaling.arn
}

resource "aws_lambda_permission" "cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.vault_remove_peer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.vault_remove_peer.arn
}

resource "aws_lambda_function" "vault_remove_peer" {
  function_name = "${random_id.environment_name.hex}-vault-remove-peer"
  filename      = "${path.module}/lambda_functions/peer_removal/main.zip"
  role          = aws_iam_role.vault_remove_peer_lambda.arn
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
