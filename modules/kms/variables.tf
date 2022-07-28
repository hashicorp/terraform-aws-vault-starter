/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

variable "common_tags" {
  type        = map(string)
  description = "(Optional) Map of common tags for all taggable AWS resources."
  default     = {}
}

variable "kms_key_deletion_window" {
  type        = number
  description = "Duration in days after which the key is deleted after destruction of the resource (must be between 7 and 30 days)."
}

variable "resource_name_prefix" {
  type        = string
  description = "Resource name prefix used for tagging and naming AWS resources"
}

variable "user_supplied_kms_key_arn" {
  type        = string
  description = "(OPTIONAL) User-provided KMS key ARN. Providing this will disable the KMS submodule from generating a KMS key used for Vault auto-unseal"
  default     = null
}
