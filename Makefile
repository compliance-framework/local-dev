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

## DOCKER COMPOSE
COMPOSE_COMMAND   := $(shell echo $$COMPOSE_COMMAND)

## DEMO
demo-go-check:
	aws-check-creds

demo-restart: demo-go-check demo-destroy demo-up           ## Tear down whole demo, then bring up
demo-destroy: demo-go-check compose-destroy aws-tf-destroy ## Tear down whole demo
demo-up: demo-go-check aws-tf compose-up                   ## Start up demo

## DEV
compose-restart: compose-down compose-up     ## Tear down environment and setup new one. (Preserves Volumes)

compose-destroy:                             ## Tear down environment and destroy data
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do destroy

compose-down:                                ## Bring down environment
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do stop

compose-up: build                            ## Bring up environment
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do start_all

compose-pull:                                ## Update all local images
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do pull

common-only-restart: compose-down            ## Bring up common services only
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do start_common

api-only-restart: compose-down               ## Bring up common services and api only
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do start_api

agents-only-restart: compose-down            ## Bring up common services and agents only
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do start_agents

build:                                       ## Bring up common services and agents only
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do build

## TF
aws-check-creds:                             # Check AWS credentials exist
	@if [ -z "$$AWS_ACCESS_KEY_ID" ] || [ -z "$$AWS_SECRET_ACCESS_KEY" ] || [ -z "$$AWS_SESSION_TOKEN" ]; then \
		echo "AWS credentials not set. Please export AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_SESSION_TOKEN."; \
		exit 1; \
	fi

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

aws-tf-destroy:                              ## Destroy Terraform for aws
	@pushd ./terraform/aws && terraform init; \
	if [ $$? -ne 0 ]; then \
		echo "Terraform init failed. Exiting."; \
		exit 1; \
	fi
	@pushd ./terraform/aws && terraform apply -destroy -auto-approve; \
	if [ $$? -ne 0 ]; then \
		echo "Terraform destroy failed. Exiting."; \
		exit 1; \
	fi

## DEBUG
print-env:                                   ## Prints environment (for debug)
	env

## Kubernetes
NAMESPACE=ccf

minikube-check-tools:
	@if ! command -v minikube &>/dev/null || ! command -v kubectl &>/dev/null; then \
		echo "❌ ERROR: Both minikube and kubectl must be installed."; \
		exit 1; \
	else \
		echo "✅ All required tools (minikube and kubectl) are installed."; \
	fi

kubernetes-run:
	@minikube start --driver=docker --network=bridged

kubernetes-ns:
	@kubectl create namespace $(NAMESPACE)

# Deploy Kubernetes resources
kubernetes-agent-deployment:
	@echo "Applying perms and agent/plugins"
	@kubectl apply -n $(NAMESPACE) -f ./demo-agents/versions/k8s-native/cluster-role.yaml
	@kubectl apply -n $(NAMESPACE) -f ./demo-agents/versions/k8s-native/cluster-role-binding.yaml
	@kubectl apply -n $(NAMESPACE) -f ./demo-agents/versions/k8s-native/deployment.yaml
