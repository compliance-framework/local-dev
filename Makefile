setup: up
	@echo "Setup backend for Demonstration"; \
	echo "Creating Plan"; plan_id=$$(curl -s localhost:8080/api/plan --header 'Content-Type: application/json' -X POST -d '{"title": "Sample Assessment Plan"}' | jq -r .id); echo "Plan ID: $${plan_id}"; \
	echo "Creating Task"; task_id=$$(curl -s localhost:8080/api/plan/$${plan_id}/tasks --header 'Content-Type: application/json' -X POST -d '{"description":"Check All the VMs","title": "VM Check","type": "action"}' | jq -r .id); echo "Task ID: $${task_id}"; \
	echo "Creating Activity"; activity_id=$$(curl -s localhost:8080/api/plan/$${plan_id}/tasks/$${task_id}/activities --header 'Content-Type: application/json' -X POST -d '{"title":"CheckVMsforport80", "description":"Thisactivitychecksfortheport", "provider":{"name":"busy", "package":"busy", "params":{"parameter1":"this-is-the-parameter-value"}, "version":"1.0.0"}, "subjects":{"title":"VMsunderFinancesubscription", "description":"Notallofthemachines", "labels":{"subscription":"finance", "env":"prod"}}}' | jq -r .id); echo "Activity ID: $${activity_id}"; \
	curl localhost:8080/api/plan/$${plan_id}/activate --header 'Content-Type: application/json' -X PUT && echo "Plan $${plan_id} Activated"
clone:
	@if [ -d "configuration-service" ]; then echo "configuration-ervice does exist."; else echo "Clonning configuration-service"; git clone git@github.com:compliance-framework/configuration-service.git; fi
	@if [ -d "assessment-runtime" ]; then echo "assessment-runtime does exist."; else echo "Clonning assessment-runtime"; git clone git@github.com:compliance-framework/assessment-runtime.git; fi
	@if [ -d "portal" ]; then echo "portal does exist."; else echo "Clonning portal"; git clone git@github.com:compliance-framework/portal.git; fi
up: clone
	docker compose up --build -d
stop:
	docker compose down
