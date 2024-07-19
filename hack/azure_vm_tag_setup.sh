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
        if ! PLANID=$(cfctl create plan -t 'title: Azure VM Tag Assessment Plan' | jq -r '.id')
        then
                echo "Not ready yet, waiting..."
                sleep 5
        else
                if [[ $PLANID == null ]]
                then
                        echo "Not ready yet, waiting..."
                        sleep 5
                else
                        break
                fi
        fi
        set -e
done
echo "Plan ID: ${PLANID}"
TASKID=$(cfctl create task -p $PLANID -d "Check all the VMs for dataclassification tag" -t "VM Check" -s "0 * * * * *" | jq -r '.id')
#TMPFILE=`mktemp` || exit 1
#envsubst < azure_vm_tag_setup_activity.yaml > $TMPFILE
#cat $TMPFILE
#ACTIVITYID=$(cfctl create activity -f $TMPFILE -p $PLANID -t $TASKID | jq -r '.id')
ACTIVITYID="$(curl -s localhost:8080/api/plan/"${PLANID}"/tasks/"${TASKID}"/activities --header 'Content-Type: application/json' -d '
{
  "title":"CheckVMs for dataclassification tag",
  "description":"This activity checks for the existence of a datalassification tag",
  "provider":{
    "name":"azure-cf-plugin",
    "tag":"seed",
    "image":"ghcr.io/compliance-framework/azure-cf-plugin",
    "configuration":{
      "yaml": "subscriptionid: '${AZURE_SUBSCRIPTION_ID}'\ntenantid: '${AZURE_TENANT_ID}'\nclientid: '${AZURE_CLIENT_ID}'"
    }
  },
  "subjects":{
    "title":"VMs",
    "description":"All VMs",
    "labels":{}
  }
}
' | jq -r .id)"
echo $ACTIVITYID
cfctl activate plan $PLANID
rm -f $TMPFILE
echo "Plan ${PLANID} Activated"
