package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/secretsmanager"
	"github.com/hashicorp/vault/api"
)

// EC2LifecycleHookEventDetail is the field of EC2LifecycleHookEvent that
// contains the information the Vault API will need
type EC2LifecycleHookEventDetail struct {
	EC2InstanceID        string `json:"EC2InstanceId"`
	AutoScalingGroupName string `json:"AutoScalingGroupName"`
	LifecycleActionToken string `json:"LifecycleActionToken"`
	LifecycleHookName    string `json:"LifecycleHookName"`
	NotificationMetadata string `json:"NotificationMetadata"`
}

// EC2LifecycleHookEvent is the event that removePeerHandler is called with
type EC2LifecycleHookEvent struct {
	Detail EC2LifecycleHookEventDetail `json:"detail"`
}

// SecretInfo holds the root token and recovery keys
type secretInfo struct {
	RootToken    string
	RecoveryKeys []string
}

func removePeerHandler(event EC2LifecycleHookEvent) error {
	log.Println("removePeerHandler has been initiated...")

	region := os.Getenv("awsRegion")
	secretID := os.Getenv("secretID")
	asgName := event.Detail.AutoScalingGroupName
	vaultNodeID := event.Detail.EC2InstanceID

	secretinfo := &secretInfo{}
	svc := secretsmanager.New(session.New(), aws.NewConfig().WithRegion(region))
	input := &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(secretID),
	}

	output, err := svc.GetSecretValue(input)
	if err != nil {
		log.Println(err)
		return err
	}
	secretString := *output.SecretString
	err = json.Unmarshal([]byte(secretString), secretinfo)
	if err != nil {
		log.Println(err)
		return err
	}

	vaultToken := secretinfo.RootToken

	idList, err := getIds(asgName, region, vaultNodeID)
	if err != nil {
		log.Println(err)
		return err
	}

	vaultNode, err := pickNode(idList, region)
	if err != nil {
		log.Println(err)
		return err
	}

	config := &api.Config{
		Address: vaultNode,
	}
	client, err := api.NewClient(config)
	if err != nil {
		log.Fatal(err)
	}

	client.SetToken(vaultToken)
	logical := client.Logical()

	// The Terraform that spins up the Vault cluster configures the Vault
	// node IDs (which are needed for peer removal) to be the same as the
	// EC2 instance IDs
	log.Printf("Vault node ID to be removed: %s\n", vaultNodeID)

	_, err = logical.Write("sys/storage/raft/remove-peer",
		map[string]interface{}{
			"server_id": vaultNodeID,
		})
	if err != nil {
		log.Println(err)
		return err
	}

	fmt.Printf("%s has been purged from raft peer list\n", vaultNodeID)

	asgSvc := autoscaling.New(session.New(), aws.NewConfig().WithRegion(region))

	asgInput := &autoscaling.CompleteLifecycleActionInput{
		AutoScalingGroupName:  aws.String(event.Detail.AutoScalingGroupName),
		InstanceId:            aws.String(event.Detail.EC2InstanceID),
		LifecycleActionResult: aws.String("CONTINUE"),
		LifecycleHookName:     aws.String(event.Detail.LifecycleHookName),
	}

	_, err = asgSvc.CompleteLifecycleAction(asgInput)
	if err != nil {
		log.Println(err)
		return err
	}

	log.Printf("lifecycle hook for %s has been completed\n", event.Detail.EC2InstanceID)
	log.Println("removePeerHandler is now finished")

	return nil
}

func getIds(asgName, region, deadNode string) ([]*string, error) {
	autoscalingSvc := autoscaling.New(session.New(), aws.NewConfig().WithRegion(region))
	autoscalingInput := &autoscaling.DescribeAutoScalingGroupsInput{
		AutoScalingGroupNames: []*string{&asgName},
	}
	output, err := autoscalingSvc.DescribeAutoScalingGroups(autoscalingInput)
	if err != nil {
		return nil, err
	}

	instanceIDArray := []*string{}
	instanceIds := output.AutoScalingGroups[0].Instances
	for _, v := range instanceIds {
		if *v.HealthStatus == "Healthy" && *v.InstanceId != deadNode {
			instanceIDArray = append(instanceIDArray, v.InstanceId)
		}
	}

	return instanceIDArray, nil
}

func pickNode(instanceIDs []*string, region string) (string, error) {
	svc := ec2.New(session.New(), aws.NewConfig().WithRegion(region))
	input := &ec2.DescribeInstancesInput{
		InstanceIds: instanceIDs,
	}

	result, err := svc.DescribeInstances(input)
	if err != nil {
		return "", err
	}

	var healthyNode string
	for _, v := range result.Reservations {
		for _, i := range v.Instances {
			if i.PrivateIpAddress == nil {
				continue
			}
			status, vaultInstance, err := checkVaultHealth(*i.PrivateIpAddress)
			if err != nil {
				continue
			}
			if status == 200 {
				healthyNode = vaultInstance
				break
			}
		}
	}
	return healthyNode, nil
}

func checkVaultHealth(ipAddress string) (int, string, error) {
	client := http.Client{
		Timeout: 2 * time.Second,
	}
	vaultNode := fmt.Sprintf("http://%s:8200", ipAddress)
	resp, err := client.Get(vaultNode)
	if err != nil {
		return 1, "", err
	}
	return resp.StatusCode, vaultNode, nil
}

func main() {
	lambda.Start(removePeerHandler)
}
