  data "terraform_remote_state" "organization" {
    backend = "s3"
    config = {
      bucket = "seccl-tf-state"
      key    = "state-files/organization"
      region = "eu-west-1"
    }
  }

  data "terraform_remote_state" "client-facing" {
    backend = "s3"
    config = {
      bucket = "seccl-tf-state"
      key    = "state-files/client-facing"
      region = "eu-west-1"
    }
  }

  data "terraform_remote_state" "shared-services" {
    backend = "s3"
    config = {
      bucket = "seccl-tf-state"
      key    = "state-files/shared-services"
      region = "eu-west-1"
    }
  }
