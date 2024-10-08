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
AR_TAG ?= latest
CS_TAG ?= latest

AZURE_SUBSCRIPTION_ID := $(shell . ./.env; echo $$AZURE_SUBSCRIPTION_ID)
AZURE_CLIENT_ID       := $(shell . ./.env; echo $$AZURE_CLIENT_ID)
AZURE_TENANT_ID       := $(shell . ./.env; echo $${AZURE_TENANT_ID})
AZURE_CLIENT_SECRET   := $(shell . ./.env; echo $$AZURE_CLIENT_SECRET)

AR_DOCKER_REPOSITORY ?= ghcr.io/compliance-framework/assessment-runtime
CS_DOCKER_REPOSITORY ?= ghcr.io/compliance-framework/configuration-service

KIND_CLUSTER_NAME=compliance-framework

help: ## Display this concise help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

help-all: ## Display all help items.
	@awk 'BEGIN {FS = ":.*#"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?#/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

check_cfctl:  # Check cfctl is available on PATH
	which cfctl || ( echo cfctl not on PATH, download from https://github.com/compliance-framework/cfctl/releases && false )

full_restart: full_destroy kind_cluster_up k8s_restart   ## Tear down whole cluster, destroy data and setup k8s anew with fresh data
full_destroy: clean_data k8s_down kind_cluster_down      ## Tear down whole cluster and destroy data

setup-plans: azure-vm-tag-setup ssh-setup privateer-example-setup  ## Set up all the plans

k8s_restart: k8s_down k8s_up  # Tear down local k8s environment and setup new one
k8s_destroy: clean_data k8s_down  # Tear down whole cluster and destroy data

azure-vm-tag-setup: check_cfctl  ## Set up a default scenario for CF
	@echo "Doing azure-vm-tag-setup"
	@bash hack/azure_vm_tag_setup.sh

ssh-setup: check_cfctl  ## Set up a default scenario for CF
	@echo "Doing ssh-setup"
	@bash hack/ssh_setup.sh

privateer-example-setup: check_cfctl  ## Set up a default scenario for CF
	@echo "Doing privateer-example-setup"
	@bash hack/privateer_example_setup.sh

kind_cluster_down:   # Destroy kind cluster
	@if kind get clusters | grep -q '^$(KIND_CLUSTER_NAME)$$'; then \
		echo "Deleting kind cluster '$(KIND_CLUSTER_NAME)'..."; \
		kind delete cluster -n $(KIND_CLUSTER_NAME); \
	else \
		echo "Kind cluster '$(KIND_CLUSTER_NAME)' does not exist."; \
	fi

kind_cluster_up:   # Create kind cluster
	@if kind get clusters | grep -q '^$(KIND_CLUSTER_NAME)$$'; then \
		echo "Kind cluster '$(KIND_CLUSTER_NAME)' already exists."; \
	else \
		echo "Creating kind cluster '$(KIND_CLUSTER_NAME)'..."; \
		kind create cluster -n $(KIND_CLUSTER_NAME); \
	fi

kind_load_images: kind_cluster_up     ## Loads local images into kind cluster
	@if [[ "$(docker images --format '{{json .}}' | jq -r '. | select(.Repository=="$(AR_DOCKER_REPOSITORY)" and .Tag=="$(AR_TAG)")' | xargs)" == "" ]]; then \
		echo "Image $(AR_DOCKER_REPOSITORY):$(AR_TAG) not available locally"; \
		docker pull $(AR_DOCKER_REPOSITORY):$(AR_TAG); \
	else \
		kind load docker-image $(AR_DOCKER_REPOSITORY):$(AR_TAG) -n $(KIND_CLUSTER_NAME); \
	fi
	@if [[ "$(docker images --format '{{json .}}' | jq -r '. | select(.Repository=="$(CS_DOCKER_REPOSITORY)" and .Tag=="$(CS_TAG)")')" == "" ]] ; then \
		echo "Image $(CS_DOCKER_REPOSITORY):$(CS_TAG) not available locally"; \
		docker pull $(CS_DOCKER_REPOSITORY):$(CS_TAG); \
	else \
		kind load docker-image $(CS_DOCKER_REPOSITORY):$(CS_TAG) -n $(KIND_CLUSTER_NAME); \
	fi


k8s_down: helm_uninstall # Stop the k8s services
	@pkill -f 'kubectl port-forward service/configuration-service' || true
	@pkill -f 'kubectl port-forward service/mongodb' || true

clean_data: k8s_down   # Removes data store in kind pv. Calls k8s_down
	@kubectl delete pvc $$(kubectl get pvc -o json | jq -r '.items[0].metadata.name') || true
	@kubectl delete pv $$(kubectl get pv -o json | jq -r '.items[0].metadata.name') || true

helm_uninstall:    # Uninstall helm package
	@if helm list -q | grep -q '^compliance-framework$$'; then \
		echo "uninstalling compliance-framework..."; \
		helm uninstall compliance-framework; \
	else \
		echo "compliance-framework already uninstalled"; \
	fi

k8s_up:   kind_cluster_up  # Bring up the k8s services
	@if helm list -q | grep -q '^compliance-framework$$'; \
	then \
		echo "Helm chart 'compliance-framework' already installed. Run 'make helm_uninstall' to remove "; \
	else \
        : Define the Helm values using environment variables; \
        helm_values="assessmentRuntime.image=$(AR_DOCKER_REPOSITORY),assessmentRuntime.tag=latest,assessmentRuntime.env.azureClientId=$(AZURE_CLIENT_ID),assessmentRuntime.env.azureClientSecret=$(AZURE_CLIENT_SECRET),assessmentRuntime.env.azureTenantId=$(AZURE_TENANT_ID),configurationService.tag=$(CS_TAG),assessmentRuntime.tag=$(AR_TAG)"; \
        : Install the Helm chart with the overridden values; \
        cd kubernetes/helm && helm install compliance-framework . --set $$helm_values; \
		/bin/echo -n "Waiting to initialise"; \
		while ! kubectl get pods | grep Running > /dev/null 2>&1; do \
			sleep 5; \
			/bin/echo -n .; \
		done; \
		while [[ $$(kubectl get pods | grep -Ev '(Running|STATUS)' | wc -l) -ne 0 ]]; do \
			sleep 5; \
			/bin/echo -n .; \
		done; \
		echo "...initialised, forwarding ports..."; \
		kubectl port-forward service/configuration-service 8080:8080 & \
		kubectl port-forward service/mongodb 27017:27017 & \
	fi

prune:     # prune docker space
	@docker system prune -f --volumes

demo:   ## Start the demo
	./demo.sh
