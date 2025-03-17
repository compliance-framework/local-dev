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

help: ## Display this concise help, ie only the porcelain target.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

help-all: ## Display all help items, ie including plumbing targets.
	@awk 'BEGIN {FS = ":.*#"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?#/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

AZURE_SUBSCRIPTION_ID := $(shell . ./.env; echo $$AZURE_SUBSCRIPTION_ID)
AZURE_CLIENT_ID       := $(shell . ./.env; echo $$AZURE_CLIENT_ID)
AZURE_TENANT_ID       := $(shell . ./.env; echo $${AZURE_TENANT_ID})
AZURE_CLIENT_SECRET   := $(shell . ./.env; echo $$AZURE_CLIENT_SECRET)

COMPOSE_COMMAND   := $(shell echo $$COMPOSE_COMMAND)

check-cfctl:  # Check cfctl is available on PATH
	which cfctl || ( echo cfctl not on PATH, download from https://github.com/compliance-framework/cfctl/releases && false )

full-restart: full-destroy compose-restart   ## Tear down compose, destroy data and setup compose anew with fresh data
full-destroy: compose-destroy ## Tear down compose and destroy data

compose-restart: compose-down compose-up ## Tear down environment and setup new one. (Preserves Volumes)

compose-destroy: ## Tear down environment and destroy data
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do destroy

compose-down: ## Bring down environment
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do stop

compose-up: build ## Bring up environment
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do start_all

compose-pull: ## Update all local images
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do pull

common-only-restart: compose-down  ## Bring up common services only
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do start_common

api-only-restart: compose-down  ## Bring up common services and api only
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do start_api

agents-only-restart: compose-down  ## Bring up common services and agents only
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do start_agents

build:  ## Bring up common services and agents only
	@COMPOSE_COMMAND="$(COMPOSE_COMMAND)" ./hack/local-shared/do build

## TF
aws-tf:
	@if [ -z "$$AWS_ACCESS_KEY_ID" ] || [ -z "$$AWS_SECRET_ACCESS_KEY" ] || [ -z "$$AWS_SESSION_TOKEN" ]; then \
		echo "AWS credentials not set. Please export AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_SESSION_TOKEN."; \
		exit 1; \
	fi
	pushd ./terraform/aws && terraform init && terraform plan -out=tfplan; \
	if [ $$? -ne 0 ]; then \
		echo "Terraform plan failed. Exiting."; \
		exit 1; \
	fi
	pushd ./terraform/aws && terraform apply -auto-approve tfplan

