# EXAMPLE: TLS Configuration on Load Balancer and Vault Nodes

## About This Example

The Vault installation module requires you to secure the load balancer that it
creates with an [HTTPS
listener](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html).
It also requires TLS certificates on all the Vault nodes in the cluster. If you
do not already have existing TLS certs that you can use for these requirements,
you can use the example code in this directory to create them and upload them to
[AWS Secrets Manager](https://aws.amazon.com/secrets-manager/) as well as [AWS
ACM](https://aws.amazon.com/certificate-manager/).

## How to Use This Module

1. Ensure your AWS credentials are [configured
   correctly](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
2. Configure required (and optional if desired) variables
3. Run `terraform init` and `terraform apply`

### Security Note:
- The [Terraform State](https://www.terraform.io/docs/language/state/index.html)
  produced by this code has sensitive data (cert private keys) stored in it.
  Please secure your Terraform state using the [recommendations listed
  here](https://www.terraform.io/docs/language/state/sensitive-data.html#recommendations).

## Required variables

* `aws_region` - AWS region to deploy resources into
* `resource_name_prefix` - string value to use as base for resource name

## Note

- Please note the following output produced by this Terraform as this
  information will be required input for the Vault installation module:
   - `lb_certificate_arn`
   - `leader_tls_servername`
   - `secrets_manager_arn`
