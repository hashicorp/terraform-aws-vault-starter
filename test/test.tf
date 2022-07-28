/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

resource "time_sleep" "wait_30s_after_vault_bootstrap" {
  create_duration = "30s"

  depends_on = [
    testingtoolsaws_ssm_runcommand.bootstrap_vault,
  ]
}

resource "testingtoolsaws_ssm_runcommand" "vault_operator_raft_list_peers" {
  document_name = "AWS-RunShellScript"

  instance_ids = [
    data.aws_instances.servers.ids[0],
  ]

  parameters = {
    commands = "VAULT_TOKEN=\"${local.bootstrap_token}\" VAULT_ADDR=\"https://127.0.0.1:8200\" VAULT_CACERT=\"/opt/vault/tls/vault-ca.pem\" VAULT_CLIENT_CERT=\"/opt/vault/tls/vault-cert.pem\" VAULT_CLIENT_KEY=\"/opt/vault/tls/vault-key.pem\" vault operator raft list-peers"
  }

  depends_on = [
    time_sleep.wait_30s_after_vault_bootstrap,
  ]
}
output "vault_operator_raft_list_peers" {
  value = testingtoolsaws_ssm_runcommand.vault_operator_raft_list_peers.outputs[0].StandardOutputContent
}
