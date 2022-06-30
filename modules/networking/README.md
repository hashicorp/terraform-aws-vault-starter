# AWS Networking Module

## Required variables

* `vpc_id` - VPC ID where Vault will be deployed

## Example usage

```hcl
module "networking" {
  source = "./modules/networking"

  vpc_id = var.vpc_id
}
```
