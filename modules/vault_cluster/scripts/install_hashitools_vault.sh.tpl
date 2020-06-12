#!/usr/bin/env bash

echo "Starting deployment from AMI: ${ami}"
export availability_zone="$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)"
export instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
export local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"

# install package

curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update
apt-get install -y vault=1:${vault_version}

echo "Installing jq"
curl --silent -Lo /bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
chmod +x /bin/jq

echo "installing AWS CLI"
apt-get install -y awscli

echo "Configuring system time"
timedatectl set-timezone UTC

# Have the instance retrieve it's own instance id
asg_name=$(aws autoscaling describe-auto-scaling-instances --instance-ids "$instance_id" --region "${region}" | jq -r ".AutoScalingInstances[].AutoScalingGroupName")

# Create an array of instance ids of your Vault servers
# We will iterate through this in the next step to get all the private ipv4
# addresses

declare -a instance_id_array

# Do not continue until the number of healthy instances from the ASG
# equal the number of nodes we expect in our cluster
# wait for them to come up and populate

# Purposefully selecting for "InService" instances since autoscaling
# groups can return instance IDs of nodes that have been terminated

while [[ "${vault_nodes}" -ne "$${#instance_id_array[*]}" ]]; do
    instance_id_array=($(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$asg_name" --region "${region}" | jq -r '.AutoScalingGroups[].Instances[] | select(.LifecycleState == "InService").InstanceId'))
    sleep 5
done

# Iterate through the instance array and retrieve all the private IPs
# These ips will be put into another array

for i in $${instance_id_array[*]}; do
	instance_ip_array+=("$(aws ec2 describe-instances --instance-id "$i" --region "${region}" | jq -r ".Reservations[].Instances[].PrivateIpAddress")")
done

cat << EOF > /etc/vault.d/vault.hcl
disable_performance_standby = true
ui = true

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "$instance_id"
$(
for i in $${instance_ip_array[*]}; do
    echo "  retry_join {
        leader_api_addr = \"http://$i:8200\"
    }"
done
)
}

cluster_addr = "http://$local_ipv4:8201"
api_addr = "http://0.0.0.0:8200"

listener "tcp" {
 address     = "0.0.0.0:8200"
 tls_disable = 1
}

seal "awskms" {
  region     = "${region}"
  kms_key_id = "${kms_key_id}"
}
EOF

chown -R vault:vault /etc/vault.d/*
chmod -R 640 /etc/vault.d/*

# this part fetches all nodes (in service or not) from the autoscaling
# group and determines whether it is safe to join the Vault cluster

vault_id_array=($(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$asg_name" --region "us-east-1" | jq -r '.AutoScalingGroups[].Instances[].InstanceId'))

# getting the IP addresses of all the nodes

for i in $${vault_id_array[*]}; do
        # excluding self since we don't need to check ourself
	if [[ "$i" == "$instance_id" ]]; then
		continue
	fi
        vault_ip_array+=("$(aws ec2 describe-instances --instance-id "$i" --region "us-east-1" | jq -r ".Reservations[].Instances[].PrivateIpAddress")")
done

# check to see if the node is entering an existing Vault cluster

existingCluster=false

for i in $${vault_ip_array[*]}; do
        status=$(curl -s "http://$i:8200/v1/sys/init" | jq -r .initialized)
	# if you get a true response back from even one node then
        # assume you are entering an existing cluster
        # (no need to check the rest of the nodes at this point)
        if [ "$status" == true ]; then
			existingCluster=true
			break
        fi
done

# the clusterCheck function will only be called if there is an existing
# cluster since we need to know if there are any dead/inactive nodes
# that haven't yet been purged from the Raft peers list before we join

clusterCheck() {
	while true; do
		safeToJoin=true
		recheck_vault_id_array=($(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$asg_name" --region "us-east-1" | jq -r '.AutoScalingGroups[].Instances[].InstanceId'))

                recheck_vault_ip_array=()
		for i in $${recheck_vault_id_array[*]}; do
			if [[ "$i" == "$instance_id" ]]; then
				continue
			fi
                # make sure to only gather the IP addresses of Vault nodes
                # that have already fully come up in the past
                # (by filtering for userdata tags) to ensure new nodes
                # coming up together ignore each other
                recheck_vault_ip_array+=("$(aws ec2 describe-instances --instance-id "$i" --region "us-east-1" | jq -r '.Reservations[].Instances[] | select(.Tags[].Key == "userdata" and .Tags[].Value == "complete").PrivateIpAddress')")
		done

		for i in $${recheck_vault_ip_array[*]}; do
                    init_status=$(curl -s "http://$i:8200/v1/sys/init" | jq -r .initialized)
                    # if there is a node lingering around and it is not
                    # returning true then it has not been fully removed
                    # from the cluster and we cannot join yet
		    if [[ "$init_status" != "true" ]]; then
				safeToJoin=false
				break
		    fi
		done
                # if it is safe to join the cluster, break out this
                # check and start the Vault service
		if [[ "$safeToJoin" == "true" ]]; then
			break
		fi

                # if it not safe to join, wait for dead nodes to be
                # removed and check cluster again

		echo "sleeping and will loop through cluster"
		echo "again to make sure everything is safe"
		sleep 10
	done
}

# if there is an existing cluster, run a check to make
# sure it is safe to join

if [[ "$existingCluster" == "true" ]]; then
	clusterCheck
fi

echo "proceeding to start Vault service"

systemctl enable vault
systemctl start vault

echo "Setup Vault profile"
cat <<PROFILE | sudo tee /etc/profile.d/vault.sh
export VAULT_ADDR="http://127.0.0.1:8200"
PROFILE

# have the node add this tag to itself after coming up
# this is important for the clusterCheck function above
aws ec2 create-tags --resources "$instance_id" --region "${region}" --tags Key=userdata,Value=complete

