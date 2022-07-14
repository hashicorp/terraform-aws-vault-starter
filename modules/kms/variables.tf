variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources."
  type        = string
}

variable "kms_key_deletion_window" {
  description = "Duration in days after which the key is deleted after destruction of the resource (must be between 7 and 30 days)."
  type        = number
  default     = 7
}

variable "kms_key_administrators" {
  # TODO: We can reduce the code used by this variable when 1.3.0 is released. This will be achieved using optional object attributes.
  description = <<DOC
    (Optional): An object map containing KMS key administratoy policy attributes.

    Used by the KMS policy.

    Inputes:
    - type: The principal type.
    - identifiers: The principal identifiers.
  DOC
  type = object({
    type         = string
    identitfiers = list(string)
  })
  default = null
}

variable "custom_kms_backend_policy" {
  description = "(Optional): A custom KMS policy to attach to the backend KMS keys."
  type        = string
  default     = null
}

variable "custom_kms_seal_unseal_policy" {
  description = "(Optional): A custom KMS policy to attach to the backend KMS keys."
  type        = string
  default     = null
}

variable "account_id" {
  description = "The account id of the current aws account. This is used only if the variable \"kms_key_administrators\" is not set."
}

variable "autoscaling_service_linked_role_arn" {
  description = "The role arn used by the autoscaling group. Used in the module managed KMS policy."
}

variable "instance_role_arn" {
  description = "The instance role arn. Used in the module managed KMS policy."
}

variable "common_tags" {
  description = "(Optional): Map of common tags for all taggable AWS resources."
  type        = map(string)
  default     = {}
}
