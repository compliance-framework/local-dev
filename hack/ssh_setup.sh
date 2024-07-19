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
	if ! PLANID=$(cfctl create plan -t 'title: Demo SSH Assessment Plan' | jq -r '.id')
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
TASKID=$(cfctl create task -p $PLANID -d "Check server is OK" -t "Server Check" -s "0 * * * * *" | jq -r '.id')
TMPFILE=`mktemp` || exit 1
envsubst < ssh_setup_activity.yaml > $TMPFILE
ACTIVITYID=$(cfctl create activity -f $TMPFILE -p $PLANID -t $TASKID | jq -r '.id')
cfctl activate plan $PLANID
rm $TMPFILE
echo "Plan ${PLANID} Activated"
