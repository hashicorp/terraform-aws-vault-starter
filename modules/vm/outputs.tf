/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

output "asg_name" {
  description = "Name of autoscaling group"
  value       = aws_autoscaling_group.vault.name
}

output "launch_template_id" {
  description = "ID of launch template for Vault autoscaling group"
  value       = aws_launch_template.vault.id
}

output "vault_sg_id" {
  description = "Security group ID of Vault cluster"
  value       = aws_security_group.vault.id
}
