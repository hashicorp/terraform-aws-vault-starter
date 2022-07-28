## Unreleased

IMPROVEMENTS:

* Update package name syntax in userdata script to prevent breakage when installing latest versions of Vault enterprise.
* Update examples directory with quickstart file that reduces number of steps to
  provision pre-reqs
* Remove data sources for AWS subnets and allow user to explicitly specify
  private subnet IDs in main module
* Update main module outputs
* Update default Vault version
* Update Terraform version pin
* Add `permissions_boundary` variable to support creating the IAM Role with a permissions boundary

## 1.0.0 (September 22, 2021)

IMPROVEMENTS:

* Updated README
* Break code into submodules and add submodule READMEs
* Deploy Vault nodes into private subnets for better security
* Better reflect Vault reference architecture and deployment guide
* Require TLS certs on nodes and load balancers
* Remove lambda functions and use autopilot features for server cleanup
* Tighten file/folder permissions created in userdata script
* Add AWS Session Manager capability for logging into nodes

## 0.2.3 (February 04, 2021)

IMPROVEMENTS:

* Clarify README

## 0.2.2 (February 04, 2021)

IMPROVEMENTS:

* Increased `wait_for_capacity_timeout` in ASG to make sure `terraform apply` doesn't time out

## 0.2.1 (August 19, 2020)

IMPROVEMENTS:

* security:
  - added security group rule to expose API/UI to allowed CIDR blocks
  - exposed `elb_internal` variable to user
* documentation: updated README

## 0.2.0 (August 13, 2020)

IMPROVEMENTS:

* Upgrading terraform block syntax for TF version 0.13.0+
* Pinning version number for `aws`, `random`, and `template` providers

## 0.1.2 (July 09, 2020)

IMPROVEMENTS:

* security: added security group rule for inbound on port 22 and variable for
  approved CIDR blocks

## 0.1.1 (July 2, 2020)

IMPROVEMENTS:

 * documentation: updated refs and corrected links
 * documentation: added CHANGELOG

## 0.1.0 (July 2, 2020)

* Initial release
