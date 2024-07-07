#!/bin/bash
#set -x
set -euo pipefail

src_folder="$(pwd)/${0%/*}"
cd $src_folder

source ../.env

echo "____________________________________________________________"
echo "Running CF setup for Azure plugin AZURE_SUBSCRIPTION_ID: $AZURE_SUBSCRIPTION_ID"

echo "Creating Plan: Sample Assessment Plan"
while true
do
	set +e
	if ! plan_id="$(curl -s localhost:8080/api/plan --header 'Content-Type: application/json' -d '{"title": "Demo Azure VM Tag Assessment Plan"}' | jq -r .id)"
	then
		echo "Not ready yet, waiting..."
		sleep 5
	else
		if [[ $plan_id == null ]]
		then
			echo "Not ready yet, waiting..."
			sleep 5
		else
			break
		fi
	fi
	set -e
done
echo "Plan ID: ${plan_id}"

echo "Creating Task: Check All the VMs"
task_id="$(curl -s localhost:8080/api/plan/"${plan_id}"/tasks --header 'Content-Type: application/json' -d '{"description": "Check All the VMs", "title": "VM Check", "type": "action", "schedule": "0 * * * * *"}' | jq -r .id)"
echo "Task ID: ${task_id}"

echo "Creating Activity: for subscription id: $AZURE_SUBSCRIPTION_ID"
activity_id="$(curl -s localhost:8080/api/plan/"${plan_id}"/tasks/"${task_id}"/activities --header 'Content-Type: application/json' -d '{"title":"CheckVMs for dataclassification tag", "description":"This activity checks for the existence of a datalassification tag", "provider":{"name":"azure-cf-plugin", "image":"ghcr.io/compliance-framework/azure-cf-plugin", "params":{}, "configuration":{"subscriptionId":"'${AZURE_SUBSCRIPTION_ID}'"}, "tag":"latest"}, "subjects":{"title":"VMs", "description":"All VMs", "labels":{}}}' | jq -r .id)"
echo "Activity ID: ${activity_id}"

curl -s "localhost:8080/api/plan/${plan_id}/activate" --header 'Content-Type: application/json' -X PUT && echo "Plan ${plan_id} Activated"
