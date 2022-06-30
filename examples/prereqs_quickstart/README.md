# EXAMPLE: Prerequisite Configuration (VPC and Secrets)

## About This Example

In order to deploy the Vault module, you must have an AWS VPC that
meets the requirements [listed in the main
README](../../README.md#how-to-use-this-module) along with TLS certs that can be
used with the Vault nodes and load balancer. If you do not already have these
resources, you can use the code provided in this directory to provision them. 

## How to Use This Module

1. Ensure your AWS credentials are [configured
   correctly](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
2. Configure required (and optional if desired) variables
3. Run `terraform init` and `terraform apply`

## Required variables

* `resource_name_prefix` - string value to use as base for resource names

## Note

- The default AWS region is `us-east-1` (as specified by the `aws_region`
  variable). You may change this if wish to deploy Vault elsewhere, but please
  be sure to change the value for the `azs` variable as well and specify the
  appropriate availability zones for your new region.

### Security Note:
- The [Terraform State](https://www.terraform.io/docs/language/state/index.html)
  produced by this code has sensitive data (cert private keys) stored in it.
  Please secure your Terraform state using the [recommendations listed
  here](https://www.terraform.io/docs/language/state/sensitive-data.html#recommendations).
