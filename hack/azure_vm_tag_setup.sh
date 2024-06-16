#!/bin/bash
#set -x
set -euo pipefail

src_folder="$(pwd)/${0%/*}"
cd $src_folder

source ../.env

echo "Running CF setup for AZURE_SUBSCRIPTION_ID: $AZURE_SUBSCRIPTION_ID"

echo "Creating Plan: Sample Assessment Plan"
plan_id="$(curl -s localhost:8080/api/plan --header 'Content-Type: application/json' -d '{"title": "Sample Assessment Plan"}' | jq -r .id)"
echo "Plan ID: ${plan_id}"

echo "Creating Task: Check All the VMs"
task_id="$(curl -s localhost:8080/api/plan/"${plan_id}"/tasks --header 'Content-Type: application/json' -d '{"description": "Check All the VMs", "title": "VM Check", "type": "action", "schedule": "0 * * * * *"}' | jq -r .id)"
echo "Task ID: ${task_id}"

echo "Creating Plan: for subscription id: $AZURE_SUBSCRIPTION_ID"
activity_id="$(curl -s localhost:8080/api/plan/"${plan_id}"/tasks/"${task_id}"/activities --header 'Content-Type: application/json' -d '{"title":"CheckVMs for dataclassification tag", "description":"This activity checks for the existence of a datalassification tag", "provider":{"name":"azurecli", "package":"azurecli", "params":{}, "configuration":{"subscriptionId":"'${AZURE_SUBSCRIPTION_ID}'"}, "version":"1.0.0"}, "subjects":{"title":"VMs", "description":"All VMs", "labels":{}}}' | jq -r .id)"
# Fuller example: activity_id="$(curl -s localhost:8080/api/plan/"${plan_id}"/tasks/"${task_id}"/activities --header 'Content-Type: application/json' -d '{"title":"CheckVMsforport80", "description":"Thisactivitychecksfortheport", "provider":{"name":"azurecli", "package":"azurecli", "params":{"parameter1":"this-is-the-parameter-value"}, "configuration":{"subscriptionId":"'${AZURE_SUBSCRIPTION_ID}'"}, "version":"1.0.0"}, "subjects":{"title":"VMsunderFinancesubscription", "description":"Notallofthemachines", "labels":{"subscription":"finance", "env":"prod"}}}' | jq -r .id)"
echo "Activity ID: ${activity_id}"

curl "localhost:8080/api/plan/${plan_id}/activate" --header 'Content-Type: application/json' -X PUT && echo "Plan ${plan_id} Activated"
