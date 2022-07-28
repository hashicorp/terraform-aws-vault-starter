// Copyright © 2014-2022 HashiCorp, Inc.
//
// This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
//

package test

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

var tfcOrg string = "hc-tfc-dev"

var repoName string = "terraform-aws-vault-starter"

func TestClusterDeployment(t *testing.T) {
	var deployEnv string
	var region string
	var azs string

	if os.Getenv("AWS_DEFAULT_REGION") != "" {
		region = os.Getenv("AWS_DEFAULT_REGION")
	} else {
		logger.Log(t, "Defaulting to us-east-1 AWS region")
		region = "us-east-1"
	}
	azs = fmt.Sprintf("[\"%sa\", \"%sb\", \"%sc\"]", region, region, region)

	cwdPath, err := os.Getwd()
	if err != nil {
		logger.Log(t, "Unable to get current working directory")
		t.FailNow()
	}

	// TFC API token will be needed to update workspaces
	tfcToken := getTfeToken(t)
	if tfcToken == "" {
		t.FailNow()
	}

	if os.Getenv("DEPLOY_ENV") != "" {
		deployEnv = os.Getenv("DEPLOY_ENV")
	} else {
		if runtime.GOOS == "windows" {
			deployEnv = "test" + os.Getenv("USERNAME")
		} else {
			deployEnv = "test" + os.Getenv("USER")
		}
	}

	// Cleanup any characters that will cause problems in resource & workspace names
	deployEnv = strings.Replace(deployEnv, ".", "", -1)

	workspaceName := repoName + "-" + deployEnv

	// Run module, and setup its destruction during CI
	// (non-CI destruction is conditionally configured after tests below)
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{TerraformDir: cwdPath, Lock: true})
	removeAutoTfvars(t, cwdPath)
	tfVars := fmt.Sprintf("azs                  = %s\ncommon_tags          = { environment = \"%s\" }\nregion               = \"%s\"\nresource_name_prefix = \"%s\"\n", azs, deployEnv, region, deployEnv)
	if os.Getenv("AWS_PERMISSIONS_BOUNDARY") != "" {
		tfVars = tfVars + fmt.Sprintf("permissions_boundary = \"%s\"\n", os.Getenv("AWS_PERMISSIONS_BOUNDARY"))
	}
	ioutil.WriteFile(filepath.Join(cwdPath, deployEnv+".auto.tfvars"), []byte(tfVars), 0644)
	if os.Getenv("GITHUB_ACTIONS") != "" {
		defer tfDestroyAndDeleteWorkspaceWithRetries(t, terraformOptions, tfcOrg, tfcToken, workspaceName, 3)
	}
	createTfcWorkspace(t, tfcOrg, tfcToken, workspaceName)
	os.Setenv("TF_WORKSPACE", workspaceName)
	terraform.Init(t, terraformOptions)
	if os.Getenv("GITHUB_ACTIONS") == "" {
		writeWorkspaceNameToTfDir(cwdPath, workspaceName)
	}
	terraform.ApplyAndIdempotent(t, terraformOptions)
	// Gather outputs
	vault_operator_raft_list_peers := terraform.Output(t, terraformOptions, "vault_operator_raft_list_peers")

	// Perform validation comparisons and collect pass/fail results
	_ = os.Unsetenv("TF_WORKSPACE")
	var testResults []bool

	// Check for the 5 peers
	instanceRegex := regexp.MustCompile("i-[0-9a-z]*")
	testResults = append(testResults, assert.Equal(t, 5, len(instanceRegex.FindAllString(vault_operator_raft_list_peers, -1))))

	// Comparisons complete; conditionally exit
	if os.Getenv("GITHUB_ACTIONS") == "" {
		if anyFalse(testResults) {
			logger.Log(t, "")
			logger.Log(t, "One or more tests failed; skipping terraform destroy")
			logger.Log(t, "You should either:")
			logger.Log(t, "1) Fix the Terraform code and re-run the tests until they pass and automatically invoke terraform destroy, or")
			logger.Log(t, "2) Run terraform destroy \"manually\", i.e. via ./destroy.sh")
			logger.Log(t, "")
		} else {
			if os.Getenv("TEST_DONT_DESTROY_UPON_SUCCESS") == "" {
				logger.Log(t, "")
				logger.Log(t, "All tests passed succesfully; proceeding to terraform destroy")
				logger.Log(t, "")
				os.Setenv("TF_WORKSPACE", workspaceName)
				terraform.Destroy(t, terraformOptions)
			} else {
				logger.Log(t, "")
				logger.Log(t, "Tests were successful, but skipping terraform destroy because TEST_DONT_DESTROY_UPON_SUCCESS environment variable is set")
				logger.Log(t, "")
			}
		}
	}
}
