# AWS Load Balancer Module

## Required variables

* `lb_certificate_arn` - ARN of TLS certificate imported into ACM for use with LB listener
* `lb_health_check_path` - The endpoint to check for Vault's health status
* `lb_subnets` - Subnets where load balancer will be deployed
* `lb_type` - The type of load balancer to provision: network or application
* `resource_name_prefix` - Resource name prefix used for tagging and naming AWS resources
* `ssl_policy` - SSL policy to use on LB listener
* `vault_sg_id` - Security group ID of Vault cluster
* `vpc_id` - VPC ID where Vault will be deployed

## Example usage

```hcl
module "loadbalancer" {
  source = "./modules/load_balancer"

  lb_certificate_arn    = var.lb_certificate_arn
  lb_health_check_path  = var.lb_health_check_path
  lb_subnets            = var.vault_subnet_ids
  lb_type               = var.lb_type
  resource_name_prefix  = var.resource_name_prefix
  ssl_policy            = var.ssl_policy
  vault_sg_id           = var.vault_sg_id
  vpc_id                = var.vpc_id
}
```
