#!/bin/bash
#set -x
set -euo pipefail

src_folder="$(pwd)/${0%/*}"
cd $src_folder

source ../.env

echo "____________________________________________________________"
echo "Running CF setup for Privateer Example plugin"

echo "Creating Plan: Privateer Example Assessment Plan"
while true
do
	set +e
	if ! PLANID=$(cfctl create plan -t 'title: Demo Privateer Example Assessment Plan' | jq -r '.id')
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
TASKID=$(cfctl create task -p $PLANID -d "Check Privateer Example" -t "Server Check" -s "0 * * * * *" | jq -r '.id')
TMPFILE=`mktemp` || exit 1
envsubst < privateer_example_setup_activity.yaml > $TMPFILE
ACTIVITYID=$(cfctl create activity -f $TMPFILE -p $PLANID -t $TASKID | jq -r '.id')
cfctl activate plan $PLANID
rm $TMPFILE
echo "Plan ${PLANID} Activated"
