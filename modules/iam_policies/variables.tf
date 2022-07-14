variable "resource_name_prefix" {
  description = "An identifier used as a preifix for the iam policies."
  type        = string
}

variable "kms_key_arn_seal" {
  description = "KMS Key ARN used for Vault auto-unseal permissions."
  type        = string
}

variable "kms_key_arn_backend" {
  description = "KMS Key ARN used for other encryption / decryption mechanisms."
  type        = string
}

variable "secret_manager_arns" {
  description = "A list of secret manager arns that will be referenced in the IAM role."
  type        = list(string)
}

variable "iam_role_arn" {
  description = "The IAM role arn module policies should be attached to."
  type        = string
  default     = null
}
