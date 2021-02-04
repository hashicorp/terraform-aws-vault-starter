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