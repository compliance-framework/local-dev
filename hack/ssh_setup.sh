#!/bin/bash
#set -x
set -euo pipefail

src_folder="$(pwd)/${0%/*}"
cd $src_folder

source ../.env

echo "____________________________________________________________"
echo "Running CF setup for SSH plugin"

# Refer to the vars to be sure they exist
CF_SSH_USERNAME=$CF_SSH_USERNAME
CF_SSH_PASSWORD=$CF_SSH_PASSWORD
CF_SSH_HOST=$CF_SSH_HOST
CF_SSH_COMMAND=$CF_SSH_COMMAND

echo "Creating Plan: Sample Assessment Plan"
while true
do
       set +e
       #if ! plan_id="$(curl -s localhost:8080/api/plan --header 'Content-Type: application/json' -d '{"title": "Demo SSH Assessment Plan"}' | jq -r .id)"
       if ! plan_id="$(curl -s localhost:8080/api/plan --header 'Content-Type: application/yaml' -d 'title: "Demo SSH Assessment Plan"' | jq -r .id)"
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

echo "Creating Task: Check Server via SSH"
task_id="$(curl -s localhost:8080/api/plan/"${plan_id}"/tasks --header 'Content-Type: application/yaml' -d '
description: "Check server is OK"
title: "Server Check"
type: "action"
"schedule": "0 * * * * *"
' | jq -r .id)"
echo "Task ID: ${task_id}"

echo "Creating Activity: ssh-cf-plugin every minute"

activity_id="$(curl -s localhost:8080/api/plan/"${plan_id}"/tasks/"${task_id}"/activities --header 'Content-Type: application/yaml' -d '
title: Check server is OK
description: This activity checks the server is OK
provider:
  name: ssh-cf-plugin
  image: ghcr.io/compliance-framework/ssh-cf-plugin
  configuration:
    username: "'${CF_SSH_USERNAME}'"
    password: "'${CF_SSH_PASSWORD}'"
    host: "'${CF_SSH_HOST}'"
    command: "'"${CF_SSH_COMMAND}"'"
    port: "'${CF_SSH_PORT:-2227}'"
  tag: latest
subjects:
  title: Server
  description: "Server: '${CF_SSH_HOST}'"
  labels: {}
' | jq -r '.id')"

echo "Activity ID: ${activity_id}"

curl -s "localhost:8080/api/plan/${plan_id}/activate" --header 'Content-Type: application/json' -X PUT && echo "Plan ${plan_id} Activated"
