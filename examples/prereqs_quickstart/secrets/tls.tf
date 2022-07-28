/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

# Generate a private key so you can create a CA cert with it.
resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create a CA cert with the private key you just generated.
resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name = "ca.vault.server.com"
  }

  validity_period_hours = 720 # 30 days

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]

  is_ca_certificate = true

  #  provisioner "local-exec" {
  #    command = "echo '${tls_self_signed_cert.ca.cert_pem}' > ./vault-ca.pem"
  #  }
}

# Generate another private key. This one will be used
# To create the certs on your Vault nodes
resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 2048

  #  provisioner "local-exec" {
  #    command = "echo '${tls_private_key.server.private_key_pem}' > ./vault-key.pem"
  #  }
}

resource "tls_cert_request" "server" {
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name = "vault.server.com"
  }

  dns_names = [
    var.shared_san,
    "localhost",
  ]

  ip_addresses = [
    "127.0.0.1",
  ]
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem   = tls_cert_request.server.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 720 # 30 days

  allowed_uses = [
    "client_auth",
    "digital_signature",
    "key_agreement",
    "key_encipherment",
    "server_auth",
  ]

  #  provisioner "local-exec" {
  #    command = "echo '${tls_locally_signed_cert.server.cert_pem}' > ./vault-crt.pem"
  #  }
}

locals {
  tls_data = {
    vault_ca   = base64encode(tls_self_signed_cert.ca.cert_pem)
    vault_cert = base64encode(tls_locally_signed_cert.server.cert_pem)
    vault_pk   = base64encode(tls_private_key.server.private_key_pem)
  }
}

locals {
  secret = jsonencode(local.tls_data)
}

