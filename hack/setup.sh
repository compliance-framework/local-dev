#/bin/bash
set -euo pipefail
echo "Creating Plan"
plan_id=$(curl -s localhost:8080/api/plan --header 'Content-Type: application/json' -X POST -d '{"title": "Sample Assessment Plan"}' | jq -r .id)
echo "Plan ID: ${plan_id}"
echo "Creating Task"
task_id=$(curl -s localhost:8080/api/plan/${plan_id}/tasks --header 'Content-Type: application/json' -X POST -d '{"description":"Check All the VMs","title": "VM Check","type": "action"}' | jq -r .id)
echo "Task ID: ${task_id}"
echo "Creating Activity"
activity_id=$(curl -s localhost:8080/api/plan/${plan_id}/tasks/${task_id}/activities --header 'Content-Type: application/json' -X POST -d '{"title":"CheckVMsforport80", "description":"Thisactivitychecksfortheport", "provider":{"name":"busy", "package":"busy", "params":{"parameter1":"this-is-the-parameter-value"}, "version":"1.0.0"}, "subjects":{"title":"VMsunderFinancesubscription", "description":"Notallofthemachines", "labels":{"subscription":"finance", "env":"prod"}}}' | jq -r .id)
echo "Activity ID: ${activity_id}"
curl localhost:8080/api/plan/${plan_id}/activate --header 'Content-Type: application/json' -X PUT && echo "Plan ${plan_id} Activated"
