// Copyright © 2014-2022 HashiCorp, Inc.
//
// This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
//

package test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/hashicorp/hcl"
)

type TfConfig struct {
	Credentials map[string]map[string]interface{} `hcl:"credentials"`
}

type TfcCreateResponseData struct {
	Id string `json:"id"`
}

type TfcCreateResponse struct {
	Data TfcCreateResponseData `json:"data"`
}

func getTfeToken(t *testing.T) string {
	if os.Getenv("TF_TOKEN_app_terraform_io") != "" {
		return os.Getenv("TF_TOKEN_app_terraform_io")
	} else {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			logger.Log(t, "")
			logger.Log(t, "Failed to determine home directory")
			return ""
		}

		terraformRcFilePath := filepath.Join(homeDir, ".terraformrc")
		if _, err := os.Stat(terraformRcFilePath); err == nil {
			terraformRcBytes, err := ioutil.ReadFile(terraformRcFilePath)
			if err != nil {
				logger.Log(t, "")
				logger.Log(t, err)
			} else {
				terraformRcObj, err := hcl.Parse(string(terraformRcBytes))
				if err != nil {
					logger.Log(t, "")
					logger.Log(t, err)
				} else {
					parsedResult := &TfConfig{}
					if err := hcl.DecodeObject(&parsedResult, terraformRcObj); err != nil {
						logger.Log(t, "")
						logger.Log(t, err)
					} else {
						if appTfIoCreds, ok := parsedResult.Credentials["app.terraform.io"]; ok {
							if token, ok := appTfIoCreds["token"]; ok {
								return fmt.Sprintf("%v", token)
							}
						}
					}
				}
			}
		}
	}
	logger.Log(t, "")
	logger.Log(t, "Failed to load Terraform Cloud credentials (have you run terraform login?)")
	return ""
}

func createTfcWorkspace(t *testing.T, tfcOrg string, tfcToken string, workspace string) {
	payload := []byte("{\"data\": {\"type\": \"workspaces\", \"attributes\": {\"execution-mode\": \"local\", \"name\": \"" + workspace + "\"}}}")
	client := &http.Client{}
	url := "https://app.terraform.io/api/v2/organizations/" + tfcOrg + "/workspaces"

	req, err := http.NewRequest(http.MethodPost, url, bytes.NewBuffer(payload))
	if err != nil {
		logger.Log(t, err)
		t.FailNow()
	}
	req.Header.Set("Authorization", "Bearer "+tfcToken)
	req.Header.Set("Content-Type", "application/vnd.api+json")

	resp, err := client.Do(req)
	if err != nil {
		// TODO: would be better to check the error and only silently continue if the workspace was already present
		logger.Log(t, err)
	}

	var res TfcCreateResponse
	json.NewDecoder(resp.Body).Decode(&res)
	if res.Data.Id != "" {
		logger.Log(t, "Tagging workspace")
		tagTfcWorkspace(t, tfcOrg, tfcToken, res.Data.Id)
	}
}

func deleteTfcWorkspace(t *testing.T, tfcOrg string, tfcToken string, workspace string) {
	client := &http.Client{}
	url := "https://app.terraform.io/api/v2/organizations/" + tfcOrg + "/workspaces/" + workspace

	req, err := http.NewRequest(http.MethodDelete, url, bytes.NewBuffer([]byte("")))
	if err != nil {
		logger.Log(t, err)
		t.FailNow()
	}
	req.Header.Set("Authorization", "Bearer "+tfcToken)
	req.Header.Set("Content-Type", "application/vnd.api+json")

	_, err = client.Do(req)
	if err != nil {
		logger.Log(t, err)
	}
}

func tagTfcWorkspace(t *testing.T, tfcOrg string, tfcToken string, workspaceId string) {
	payload := []byte("{\"data\": [{\"type\": \"tags\", \"attributes\": { \"name\": \"integrationtest\" }}]}")
	client := &http.Client{}
	url := "https://app.terraform.io/api/v2/workspaces/" + workspaceId + "/relationships/tags"

	req, err := http.NewRequest(http.MethodPost, url, bytes.NewBuffer(payload))
	if err != nil {
		logger.Log(t, err)
		t.FailNow()
	}
	req.Header.Set("Authorization", "Bearer "+tfcToken)
	req.Header.Set("Content-Type", "application/vnd.api+json")

	_, err = client.Do(req)
	if err != nil {
		// TODO: would be better to check the error and only silently continue if the tag(s) are already present
		logger.Log(t, err)
	}
}

func setWorkspaceToLocalMode(t *testing.T, tfcOrg string, tfcToken string, workspace string) {
	payload := []byte("{\"data\": {\"type\": \"workspaces\", \"attributes\": {\"execution-mode\": \"local\"}}}")
	client := &http.Client{}
	url := "https://app.terraform.io/api/v2/organizations/" + tfcOrg + "/workspaces/" + workspace

	req, err := http.NewRequest(http.MethodPatch, url, bytes.NewBuffer(payload))
	if err != nil {
		logger.Log(t, err)
		t.FailNow()
	}
	req.Header.Set("Authorization", "Bearer "+tfcToken)
	req.Header.Set("Content-Type", "application/vnd.api+json")

	_, err = client.Do(req)
	if err != nil {
		logger.Log(t, err)
		t.FailNow()
	}
}

func tfDestroyAndDeleteWorkspace(t *testing.T, tfOptions *terraform.Options, tfcOrg string, tfcToken string, workspace string) {
	os.Setenv("TF_WORKSPACE", workspace)
	terraform.Destroy(t, tfOptions)
	logger.Log(t, "")
	logger.Log(t, "Terraform destroy successful; deleting TFC workspace "+workspace)
	logger.Log(t, "")
	deleteTfcWorkspace(t, tfcOrg, tfcToken, workspace)
	err := os.Unsetenv("TF_WORKSPACE")
	if err != nil {
		logger.Log(t, err)
	}
}

func tfDestroyAndDeleteWorkspaceWithRetries(t *testing.T, tfOptions *terraform.Options, tfcOrg string, tfcToken string, workspace string, attempts int) {
	os.Setenv("TF_WORKSPACE", workspace)
	tfDestroyWithRetries(t, tfOptions, attempts)
	logger.Log(t, "")
	logger.Log(t, "Terraform destroy successful; deleting TFC workspace "+workspace)
	logger.Log(t, "")
	deleteTfcWorkspace(t, tfcOrg, tfcToken, workspace)
	err := os.Unsetenv("TF_WORKSPACE")
	if err != nil {
		logger.Log(t, err)
	}
}

func anyFalse(s []bool) bool {
	for _, v := range s {
		if v == false {
			return true
		}
	}
	return false
}

// Remove any .auto.tfvars files present in path
func removeAutoTfvars(t *testing.T, path string) {
	files, err := ioutil.ReadDir(path)
	if err != nil {
		logger.Log(t, "")
		logger.Log(t, "Error reading module directory to cleanup .auto.tfvars files")
		logger.Log(t, "")
		t.FailNow()
	}

	for _, file := range files {
		if file.IsDir() == false && strings.HasSuffix(file.Name(), ".auto.tfvars") {
			err = os.Remove(filepath.Join(path, file.Name()))
			if err != nil {
				logger.Log(t, "")
				logger.Log(t, "Error deleting .auto.tfvars file")
				logger.Log(t, "")
				t.FailNow()
			}
		}
	}
}

// Repeatedly call "terraform apply -destroy" and ignore errors until the final attempt
// This can be used to work around resources that don't always destroy correctly on the first attempt
func tfDestroyWithRetries(t *testing.T, terraformOpts *terraform.Options, attempts int) {
	for i := 1; i < attempts; i++ {
		_, err := terraform.DestroyE(t, terraformOpts)
		if err == nil {
			return
		}
		logger.Log(t, "Error encountered while running \"terraform apply -destroy\"; retrying...")
	}
	terraform.Destroy(t, terraformOpts)
}

// Persist Terraform Workspace name so users can run diagnostic
// Terraform commands without setting the TF_WORKSPACE env var or
// running "terraform workspace select" first
func writeWorkspaceNameToTfDir(modulePath string, workspaceName string) {
	ioutil.WriteFile(filepath.Join(modulePath, ".terraform", "environment"), []byte(workspaceName), 0644)
}
