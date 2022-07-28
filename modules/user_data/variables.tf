/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

variable "aws_region" {
  type        = string
  description = "AWS region where Vault is being deployed"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS Key ARN used for Vault auto-unseal"
}

variable "leader_tls_servername" {
  type        = string
  description = "One of the shared DNS SAN used to create the certs use for mTLS"
}

variable "resource_name_prefix" {
  type        = string
  description = "Resource name prefix used for tagging and naming AWS resources"
}

variable "secrets_manager_arn" {
  type        = string
  description = "Secrets manager ARN where TLS cert info is stored"
}

variable "user_supplied_userdata_path" {
  type        = string
  description = "File path to custom userdata script being supplied by the user"
  default     = null
}

variable "vault_version" {
  type        = string
  description = "Vault version"
}
