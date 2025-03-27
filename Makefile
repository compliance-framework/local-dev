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
demo-go-check: aws-check-creds
demo-restart: demo-go-check demo-destroy demo-up           ## Tear down whole demo, then bring up
demo-destroy: demo-go-check compose-destroy aws-tf-destroy ## Tear down whole demo
demo-up:      demo-go-check aws-tf compose-up              ## Start up demo

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

## PRE-FLIGHT CHECKS
docker-check:                                # Check docker command works
	@echo "Checking compose command..."
	@if eval $$COMPOSE_COMMAND ls >/dev/null 2>&1 || podman info >/dev/null 2>&1; then \
		true; \
	else \
		echo '================================================================================'; \
		echo 'Docker should be set up, eg: export COMPOSE_COMMAND="docker compose"'; \
		echo '================================================================================'; \
		exit 1; \
	fi
	@echo "...done."

aws-check-creds:                             # Check AWS credentials exist
	@echo "Checking AWS creds..."
	@if [ -z "$$AWS_ACCESS_KEY_ID" ] || [ -z "$$AWS_SECRET_ACCESS_KEY" ] || [ -z "$$AWS_SESSION_TOKEN" ]; then \
		echo "AWS credentials not set. Please export AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_SESSION_TOKEN."; \
		exit 1; \
	fi
	@if aws sts get-caller-identity >/dev/null 2>&1; then \
		true; \
	else \
		echo "'aws sts get-caller-identity' was not run successfully, make sure you are logged in by running 'aws sts get-session-token --profile ccf-demo-1 --duration-seconds 129600', updating '.env', and running 'source .env' before re-running"; \
	fi
	@echo "...done."

azure-check-creds:
	@echo "Checking Azure creds..."
	@if [ -z "$$AZURE_CLIENT_ID" ] || [ -z "$$AZURE_CLIENT_SECRET" ] || [ -z "$$AZURE_TENANT_ID" ] || [ -z "$$AZURE_SUBSCRIPTION_ID" ]; then \
		echo "Azure credentials not set. Please export AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID and AZURE_SUBSCRIPTION_ID."; \
		exit 1; \
	fi
	@echo "...done."

azure-create-service-principal:
	@az ad sp create-for-rbac --name terraform-sp \
		--role Contributor \
		--scopes /subscriptions/$(AZURE_SUBSCRIPTION_ID)

azure-login: azure-check-creds
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
azure-tf: azure-login
	@pushd ./terraform/azure && terraform init; \
	if [ $$? -ne 0 ]; then \
		echo "Azure Terraform init failed. Exiting."; \
		exit 1; \
	fi
	@pushd ./terraform/azure && terraform plan -out tfplan; \
	if [ $$? -ne 0 ]; then \
		echo "Azure Terraform plan failed. Exiting."; \
		exit 1; \
	fi
	@pushd ./terraform/azure && terraform apply -auto-approve tfplan

azure-tf-destroy: azure-login
	@pushd ./terraform/azure && terraform init; \
	if [ $$? -ne 0 ]; then \
		echo "Azure Terraform init failed. Exiting."; \
		exit 1; \
	fi
	@pushd ./terraform/azure && terraform apply -destroy -auto-approve; \
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
