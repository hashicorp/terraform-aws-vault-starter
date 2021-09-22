# AWS VM Module

## Required variables

* `aws_iam_instance_profile` - IAM instance profile name to use for Vault instances
* `lb_type` - The type of load balancer being used to front Vault instances
* `resource_name_prefix` - Resource name prefix used for tagging and naming AWS resources
* `userdata_script` - Userdata script for EC2 instance. Must be base64-encoded.
* `vault_lb_sg_id` - Security group ID of Vault load balancer (will not be read if you are using a network load balancer)
* `vault_subnets` - Private subnets where Vault will be deployed
* `vault_target_group_arn` - Target group ARN to register Vault nodes with
* `vpc_id` - VPC ID where Vault will be deployed

## Example usage

```hcl
module "vm" {
  source = "./modules/vm"

  aws_iam_instance_profile  = var.aws_iam_instance_profile
  instance_type             = var.instance_type
  lb_type                   = var.lb_type
  resource_name_prefix      = var.resource_name_prefix
  userdata_script           = var.userdata_script
  vault_lb_sg_id            = var.vault_lb_sg_id
  vault_subnets             = var.vault_subnet_ids
  vault_target_group_arn    = var.vault_target_group_arn
  vpc_id                    = var.vpc_id
}
```
