# Vault AWS Module

This is a Terraform module for provisioning Vault with [integrated
storage](https://www.vaultproject.io/docs/concepts/integrated-storage) on AWS.
This module defaults to setting up a cluster with 5 Vault nodes (as recommended
by the [Vault with Integrated Storage Reference
Architecture](https://learn.hashicorp.com/vault/operations/raft-reference-architecture)).

## About This Module
This module implements the [Vault with Integrated Storage Reference
Architecture](https://learn.hashicorp.com/vault/operations/raft-reference-architecture#node)
on AWS using the open source version of Vault 1.8+.

## How to Use This Module

- Ensure your AWS credentials are [configured
  correctly](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
  and have permission to use the following AWS services:
    - Amazon Certificate Manager (ACM)
    - Amazon EC2
    - Amazon Elastic Load Balancing (ELB)
    - AWS Identity & Access Management (IAM)
    - AWS Key Management System (KMS)
    - Amazon Secrets Manager
    - AWS Systems Manager Session Manager (optional - used to connect to EC2
      instances with session manager using the AWS CLI)
    - Amazon VPC

- To deploy without an existing VPC, use the [example
  VPC](https://github.com/hashicorp/terraform-aws-vault-starter/tree/main/examples/aws-vpc)
  code to build out the pre-requisite environment. Ensure you are selecting a
  region that has at least three [AWS Availability
  Zones](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-availability-zones).

- To deploy into an existing VPC, ensure the following components exist and are
  routed to each other correctly:
  - Three public subnets
  - Three [NAT
    gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) (one in each public subnet)
  - Three private subnets (please make sure your private subnets are
    specifically tagged so you can identify them. The Vault module will use
    these tags to deploy the Vault servers into them.)

- Use the
  [example](https://github.com/hashicorp/terraform-aws-vault-starter/tree/main/examples/aws-secrets-manager-acm)
  code to create TLS certs and store them in [AWS Secrets
  Manager](https://aws.amazon.com/secrets-manager/) along with importing them
  into [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/)

- Create a Terraform configuration that pulls in the Vault module and specifies
  values for the required variables:

```hcl
provider "aws" {
  # your AWS region
  region = "us-east-1"
}

module "vault" {
  source  = "hashicorp/vault-starter/aws"
  version = "1.0.0"

  # prefix for tagging/naming AWS resources
  resource_name_prefix = "test"
  # VPC ID you wish to deploy into
  vpc_id = "vpc-abc123xxx"
  # private subnet tags are required and allow you to filter which
  # subnets you will deploy your Vault nodes into
  private_subnet_tags = {
    Vault = "deploy"
  }
  # AWS Secrets Manager ARN where TLS certs are stored
  secrets_manager_arn = "arn:aws::secretsmanager:abc123xxx"
  # The shared DNS SAN of the TLS certs being used
  leader_tls_servername = "vault.server.com"
  # The cert ARN to be used on the Vault LB listener
  lb_certificate_arn = "arn:aws:acm:abc123xxx"
}
```

  - Run `terraform init` and `terraform apply`

  - You must
    [initialize](https://www.vaultproject.io/docs/commands/operator/init#operator-init)
    your Vault cluster after you create it. Begin by logging into your Vault
    cluster using one of the following methods:
      - Using [Session
        Manager](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/session-manager.html)
      - SSH (you must provide the optional SSH key pair through the `key_name`
        variable and set a value for the `allowed_inbound_cidrs_ssh` variable.
          - Please note this Vault cluster is not public-facing. If you want to
            use SSH from outside the VPC, you are required to establish your own
            connection to it (VPN, etc).

**Please Note**: if you are using Session Manager to connect to your nodes and
will run vault commands as the default `ssm-user`, it is important you first run
the following command to source the environment variables that Vault requires:

```
$ . /etc/profile
```

  - To initialize the Vault cluster, run the following commands:

```
$ vault operator init
```

  - This should return back the following output which includes the recovery
    keys and initial root token (omitted here):

```
...
Success! Vault is initialized
```

  - Please securely store the recovery keys and initial root token that Vault
    returns to you.
  - To check the status of your Vault cluster, export your Vault token and run
    the
    [list-peers](https://www.vaultproject.io/docs/commands/operator/raft#list-peers)
    command:

```
$ export VAULT_TOKEN="<your Vault token>"
$ vault operator raft list-peers
```

- Please note that Vault does not enable [dead server
  cleanup](https://www.vaultproject.io/docs/concepts/integrated-storage/autopilot#dead-server-cleanup)
  by default. You must enable this to avoid manually managing the Raft
  configuration every time there is a change in the Vault ASG. To enable dead
  server cleanup, run the following command:

 ```
$ vault operator raft autopilot set-config \
    -cleanup-dead-servers=true \
    -dead-server-last-contact-threshold=10 \
    -min-quorum=3
 ```

- You can verify these settings after you apply them by running the following command:

```
$ vault operator raft autopilot get-config
```

## License

This code is released under the Mozilla Public License 2.0. Please see
[LICENSE](https://github.com/hashicorp/terraform-aws-vault-starter/blob/main/LICENSE)
for more details.
