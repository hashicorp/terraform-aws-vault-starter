package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
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
// contains the information the Lambda function needs
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

type secretInfo struct {
	RootToken    string
	RecoveryKeys []string
}

func main() {
	lambda.Start(initializeClusterHandler)
}

func initializeClusterHandler(event EC2LifecycleHookEvent) error {
	log.Println("initializeClusterHandler has been initiated...")
	asgName := event.Detail.AutoScalingGroupName
	region := os.Getenv("awsRegion")
	secretID := os.Getenv("secretID")

	idList, err := getIds(asgName, region)
	if err != nil {
		log.Println(err)
		return err
	}

	leader, err := pickLeader(idList, region)
	if err != nil {
		log.Println(err)
		return err
	}

	vaultInitialize(leader, secretID, region)

	return nil
}

func getIds(asgName, region string) ([]*string, error) {
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
		if *v.HealthStatus == "Healthy" {
			instanceIDArray = append(instanceIDArray, v.InstanceId)
		}
	}

	return instanceIDArray, nil
}

func pickLeader(instanceIDs []*string, region string) (string, error) {
	svc := ec2.New(session.New(), aws.NewConfig().WithRegion(region))
	input := &ec2.DescribeInstancesInput{
		InstanceIds: instanceIDs,
	}

	result, err := svc.DescribeInstances(input)
	if err != nil {
		return "", err
	}

	instanceIPArray := []string{}
	for _, v := range result.Reservations {
		for _, i := range v.Instances {
			instanceIPArray = append(instanceIPArray, *i.PrivateIpAddress)
		}
	}

	// Pick a random node to return (this node will be initialized)
	rand.Seed(time.Now().Unix())
	return instanceIPArray[rand.Intn(len(instanceIPArray))], nil
}

func vaultInitialize(vaultAddress, secretID string, region string) error {
	vaultEndpoint := fmt.Sprintf("http://%s:8200", vaultAddress)

	config := &api.Config{
		Address: vaultEndpoint,
	}
	client, err := api.NewClient(config)
	if err != nil {
		return err
	}

	sys := client.Sys()

	initRequest := &api.InitRequest{
		RecoveryShares:    5,
		RecoveryThreshold: 3,
	}

	initResponse, err := sys.Init(initRequest)
	if err != nil {
		return err
	}

	fmt.Printf("%s has been initialized\n", vaultAddress)

	secret := secretInfo{
		RootToken:    initResponse.RootToken,
		RecoveryKeys: initResponse.RecoveryKeys,
	}

	secretText, err := json.Marshal(secret)
	if err != nil {
		return err
	}

	svc := secretsmanager.New(session.New(), aws.NewConfig().WithRegion(region))
	input := &secretsmanager.UpdateSecretInput{
		SecretId:     aws.String(secretID),
		SecretString: aws.String(string(secretText)),
	}

	result, err := svc.UpdateSecret(input)
	if err != nil {
		return err
	}

	fmt.Printf("%s has been updated\n", *result.Name)

	return nil
}
