/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

output "lb_certificate_arn" {
  description = "ARN of ACM cert to use with Vault LB listener"
  value       = aws_acm_certificate.vault.arn
}

output "leader_tls_servername" {
  description = "Shared SAN that will be given to the Vault nodes configuration for use as leader_tls_servername"
  value       = var.shared_san
}

output "secrets_manager_arn" {
  description = "ARN of secrets_manager secret"
  value       = aws_secretsmanager_secret.tls.arn
}
