# AWS Networking Module

## Required variables

* `private_subnet_tags` - Tags which specify the subnets to deploy Vault into
* `vpc_id` - VPC ID where Vault will be deployed

## Example usage

```hcl
module "networking" {
  source = "./modules/networking"

  private_subnet_tags = var.private_subnet_tags
  vpc_id              = var.vpc_id
}
```
