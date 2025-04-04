# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI catalog characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

## HELP
help: ## Display this concise help, ie only the porcelain target.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

help-all: ## Display all help items, ie including plumbing targets.
	@awk 'BEGIN {FS = ":.*#"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?#/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

## AZURE
AZURE_SUBSCRIPTION_ID := $(shell . ./.env; echo $$AZURE_SUBSCRIPTION_ID)
AZURE_CLIENT_ID       := $(shell . ./.env; echo $$AZURE_CLIENT_ID)
AZURE_TENANT_ID       := $(shell . ./.env; echo $${AZURE_TENANT_ID})
AZURE_CLIENT_SECRET   := $(shell . ./.env; echo $$AZURE_CLIENT_SECRET)

## Kubernetes
K8S_NAMESPACE=ccf

## DOCKER COMPOSE
COMPOSE_COMMAND   := $(shell echo $$COMPOSE_COMMAND)

## DEMO
demo-go-check: docker-check aws-check-creds azure-check-creds
demo-restart: demo-go-check demo-destroy demo-up                            ## Tear down whole demo, then bring up
demo-destroy: demo-go-check compose-destroy aws-tf-destroy azure-tf-destroy ## Tear down whole demo
demo-up:      demo-go-check aws-tf azure-tf compose-up load-catalogs        ## Start up demo

## DEV
compose-restart: compose-down compose-up     ## Tear down environment and setup new one. (Preserves Volumes)

compose-destroy: docker-check                ## Tear down environment and destroy data
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do destroy

compose-down: docker-check                   ## Bring down environment
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do stop

compose-up: build                            ## Bring up environment
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do start_all

compose-pull: docker-check                   ## Update all local images
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do pull

common-only-restart: compose-down            ## Bring up common services only
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do start_common

api-only-restart: compose-down               ## Bring up common services and api only
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do start_api

agents-only-restart: compose-down            ## Bring up common services and agents only
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do start_agents

build: docker-check                          ## Bring up common services and agents only
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do build

load-catalogs:                               ## Load in the catalogs for the demo
	@echo "================================================================================"
	@echo "Loading catalogs... (duplicate errors are OK)"
	@curl --request POST --url http://localhost:8080/api/catalogs --header 'Content-Type: multipart/form-data' --form file=@./catalogs/SAMA_CSF_1.0_catalog.json
	@curl --request POST --url http://localhost:8080/api/catalogs --header 'Content-Type: multipart/form-data' --form file=@./catalogs/SAMA_ITGF_1.0_catalog.json
	@curl --request POST --url http://localhost:8080/api/catalogs --header 'Content-Type: multipart/form-data' --form file=@./catalogs/NIST_SP-800-53_rev5_catalog.json
	@echo "... done"

## PRE-FLIGHT CHECKS
docker-check:                                # Check docker command works
	@echo "================================================================================"
	@echo "Checking compose command..."
	@if eval $$COMPOSE_COMMAND ls >/dev/null 2>&1 || podman info >/dev/null 2>&1; then \
		true; \
	else \
		echo '================================================================================'; \
		echo 'Docker should be running and the compose command set up, eg: export COMPOSE_COMMAND="docker compose"'; \
		echo '================================================================================'; \
		exit 1; \
	fi
	@echo "...done."

init-env: aws-init-env azure-init-env        # Ensure the .env file is set up for use with dummy values

aws-init-env:                                # Ensure the .env file is set up for use with dummy values for AWS
	@for var in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN; do grep -q "^$$var=" .env || echo "$$var=" >> .env; done

aws-check-creds: aws-init-env                      # Check AWS credentials exist
	@echo "================================================================================"
	@echo "Checking AWS creds..."
	@if [ -z "$$AWS_ACCESS_KEY_ID" ] || [ -z "$$AWS_SECRET_ACCESS_KEY" ] || [ -z "$$AWS_SESSION_TOKEN" ]; then \
		echo "================================================================================"; \
		echo "AWS credentials not set (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN)."; \
		echo "Run: source <(grep '^[A-Z_]' .env | sed 's/^/export /')"; \
		echo "================================================================================"; \
		exit 1; \
	fi
	@if aws sts get-caller-identity >/dev/null 2>&1; then \
		true; \
	else \
		echo "'aws sts get-caller-identity' was not run successfully, make sure you are logged in by running: make aws-get-sts && source <(grep '^[A-Z_]' .env | sed 's/^/export /')"; \
	fi
	@echo "...done."

aws-get-sts: aws-init-env                          # Update .env file with aws details
	@echo "================================================================================"
	@echo "Getting AWS creds..."
	@aws sts get-session-token --profile ccf-demo-1 --duration-seconds 129600 | tee | grep -E '(Key|Token)' | sed 's/^[^"]*"\([a-zA-Z]*\)": "\([^"]*\)",/\1=\2/' | sed 's/AccessKeyId/AWS_ACCESS_KEY_ID/;s/SecretAccessKey/AWS_SECRET_ACCESS_KEY/;s/SessionToken/AWS_SESSION_TOKEN/' | while IFS='=' read -r key value; do sed -i.bak "s|^$$key=.*|$$key=$$value|" .env; done
	@echo "Run: source <(grep '^[A-Z_]' .env | sed 's/^/export /')"
	@echo "...done."

azure-init-env:                                     # Ensure the .env file is set up for use with dummy values for Azure
	@for var in AZURE_SUBSCRIPTION_ID AZURE_CLIENT_SECRET AZURE_CLIENT_ID AZURE_TENANT_ID; do grep -q "^$$var=" .env || echo "$$var=" >> .env; done

azure-check-tools:
	@if ! command -v az &>/dev/null; then \
		echo "❌ ERROR: az needs installing."; \
		exit 1; \
	else \
		echo "✅ az installed."; \
	fi

azure-check-subscription-id: azure-check-tools
	@echo "================================================================================"
	@echo "Checking subscription id..."
	@if [ -z "$$AZURE_SUBSCRIPTION_ID" ]; then \
		echo "Azure subscription ID not set: Please export AZURE_SUBSCRIPTION_ID."; \
		exit 1; \
	fi
	@if [ "$$AZURE_SUBSCRIPTION_ID" != "$$(az account show --query id --output tsv)" ]; then echo "AZURE_SUBSCRIPTION_ID different from output of: az account show --query id --output tsv"; fi
	@echo "...done."

azure-check-creds: azure-check-subscription-id azure-check-tools
	@echo "================================================================================"
	@echo "Checking Azure creds..."
	@if [ -z "$$AZURE_CLIENT_ID" ] || [ -z "$$AZURE_CLIENT_SECRET" ] || [ -z "$$AZURE_TENANT_ID" ] || [ -z "$$AZURE_SUBSCRIPTION_ID" ]; then \
		echo "Azure credentials not set. Please export AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID and AZURE_SUBSCRIPTION_ID."; \
		exit 1; \
	fi
	@echo "...done."

azure-create-service-principal: azure-init-env azure-check-subscription-id    ## Get Azure creds (requires AZURE_SUBSCRIPTION_ID in env)
	@echo "================================================================================"
	@echo "Getting Azure creds and updating .env file..."
	@az ad sp create-for-rbac \
		--name terraform-sp-$(USER) \
		--role Contributor \
		--scopes /subscriptions/$(AZURE_SUBSCRIPTION_ID) | \
			grep -E "(appId|password|tenant)" | \
			sed 's/",/"/' | \
			sed 's/^[^"]*"\([a-zA-Z]*\)": "\([^"]*\)"/\1=\2/' | \
			sed 's/appId/AZURE_CLIENT_ID/;s/password/AZURE_CLIENT_SECRET/;s/tenant/AZURE_TENANT_ID/' | \
			while IFS='=' read -r key value; do sed -i.bak "s|^$$key=.*|$$key=$$value|" .env; done
	@echo "... done, now run: source <(grep '^[A-Z_]' .env | sed 's/^/export /')"

azure-login: azure-check-creds             ## Log in to Azure, using already-setup creds in env
	@az login --service-principal \
	  --username "$(AZURE_CLIENT_ID)" \
	  --password "$(AZURE_CLIENT_SECRET)" \
	  --tenant "$(AZURE_TENANT_ID)"

minikube-check-tools:                        ## Check tools are available for running kube locally
	@if ! command -v minikube &>/dev/null || ! command -v kubectl &>/dev/null; then \
		echo "❌ ERROR: Both minikube and kubectl must be installed."; \
		exit 1; \
	else \
		echo "✅ All required tools (minikube and kubectl) are installed."; \
	fi

## AWS TF
aws-tf: aws-check-creds                      ## Set up Terraform for aws
	@pushd ./terraform/aws && terraform init; \
	if [ $$? -ne 0 ]; then \
		echo "Terraform init failed. Exiting."; \
		exit 1; \
	fi
	@pushd ./terraform/aws && terraform plan -out tfplan; \
	if [ $$? -ne 0 ]; then \
		echo "Terraform plan failed. Exiting."; \
		exit 1; \
	fi
	@pushd ./terraform/aws && terraform apply -auto-approve tfplan

aws-tf-destroy: aws-check-creds              ## Destroy Terraform for aws
	@pushd ./terraform/aws && terraform init; \
	if [ $$? -ne 0 ]; then \
		echo "AWS Terraform init failed. Exiting."; \
		exit 1; \
	fi
	@pushd ./terraform/aws && terraform apply -destroy -auto-approve; \
	if [ $$? -ne 0 ]; then \
		echo "AWS Terraform destroy failed. Exiting."; \
		exit 1; \
	fi

## Azure TF
azure-tf: azure-login  ## Set up Terraform for Azure
	@pushd ./terraform/azure && \
	terraform init -input=false && \
	terraform plan -input=false -var "subscription_id=${AZURE_SUBSCRIPTION_ID}" -var "tenant_id=${AZURE_TENANT_ID}" -out tfplan && \
	terraform apply -auto-approve tfplan; \
	popd

azure-tf-destroy: azure-login
	@pushd ./terraform/azure && terraform init; \
	if [ $$? -ne 0 ]; then \
		echo "Azure Terraform init failed. Exiting."; \
		exit 1; \
	fi
	@pushd ./terraform/azure && terraform apply -input=false -var "subscription_id=${AZURE_SUBSCRIPTION_ID}" -var "tenant_id=${AZURE_TENANT_ID}" -destroy -auto-approve; \
	if [ $$? -ne 0 ]; then \
		echo "Azure Terraform destroy failed. Exiting."; \
		exit 1; \
	fi

## KUBERNETES
minikube-run: minikube-check-tools           ## Start up minikube
	@minikube status -f='{{.Host}}' | grep Running >/dev/null 2>&1 || minikube start --driver=docker --network=bridged --extra-config=kubelet.enable-debugging-handlers=true

kubernetes-ns: minikube-run                  ## Create minikube namespace
	@kubectl get ns | grep $(K8S_NAMESPACE) >/dev/null 2>&1 || kubectl create namespace $(K8S_NAMESPACE)

# Deploy Kubernetes resources
kubernetes-agent-deployment: kubernetes-ns   ## Deploy agent to Kubernetes
	@echo "Applying perms and agent/plugins"
	@kubectl apply -n $(K8S_NAMESPACE) -f ./demo-agents/versions/k8s-native/cluster-role.yaml
	@kubectl apply -n $(K8S_NAMESPACE) -f ./demo-agents/versions/k8s-native/cluster-role-binding.yaml
	@kubectl apply -n $(K8S_NAMESPACE) -f ./demo-agents/versions/k8s-native/deployment.yaml

## DEBUG
print-env:                                   ## Prints environment (for debug)
	env
