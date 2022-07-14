output "cloud_auto_join_iam_policy_name" {
  description = "The name for the cloud_auto_join IAM inline policy."
  value       = aws_iam_role_policy.cloud_auto_join.name
}

output "auto_unseal_iam_policy_name" {
  description = "The name for the auto_unseal IAM inline policy."
  value       = aws_iam_role_policy.auto_unseal.name
}

output "session_manager_policy_name" {
  description = "The name for the session_manager IAM inline policy."
  value       = aws_iam_role_policy.session_manager.name
}

output "secrets_manager_policy_name" {
  description = "The name for the secrets_manager IAM inlinepolicy."
  value       = aws_iam_role_policy.secrets_manager.name
}

