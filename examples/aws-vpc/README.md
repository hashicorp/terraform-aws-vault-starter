# EXAMPLE: Create a Prerequisite VPC

## About This Example

In order to deploy the Vault Enterprise module, you must have an AWS VPC that
meets the requirements [listed in the main
README](../../README.md#how-to-use-this-module). If you do not already have an
existing VPC, you can use the example code in this directory to provision it
along with all the other required infrastructure components.

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

- You must note the value for `private_subnet_tags` (this value is provided as
  output to you after Terraform runs). This will be required input to the Vault
  installation module and allows the Vault nodes to be correctly deployed in
  private subnets. If you change the default value set for `private_subnet_tags`
  in this example, please be sure to provide it when running the Vault
  installation module as well.