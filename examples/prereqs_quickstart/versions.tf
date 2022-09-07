terraform {
  required_version = ">= 1.2.1"

  required_providers {
    aws = ">= 4.0.0"
    tls = ">= 3.0.0, < 4.0.0"
  }
}
