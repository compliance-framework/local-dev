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
PR_TAG ?= latest

AZURE_SUBSCRIPTION_ID := $(shell . ./.env; echo $$AZURE_SUBSCRIPTION_ID)
AZURE_CLIENT_ID       := $(shell . ./.env; echo $$AZURE_CLIENT_ID)
AZURE_TENANT_ID       := $(shell . ./.env; echo $${AZURE_TENANT_ID})
AZURE_CLIENT_SECRET   := $(shell . ./.env; echo $$AZURE_CLIENT_SECRET)


help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

restart: down up azure-vm-tag-setup ssh-setup    ## Tear down environment and setup new one

azure-vm-tag-setup:  ## Set up a default scenario for CF
	@bash hack/azure_vm_tag_setup.sh

ssh-setup:  ## Set up a default scenario for CF
	@bash hack/ssh_setup.sh

up:    ## Bring up the services
	@AZURE_SUBSCRIPTION_ID=$(AZURE_SUBSCRIPTION_ID) AZURE_TENANT_ID=$(AZURE_TENANT_ID) AZURE_CLIENT_ID=$(AZURE_CLIENT_ID) AZURE_CLIENT_SECRET=$(AZURE_CLIENT_SECRET) AR_TAG=$(AR_TAG) CS_TAG=$(CS_TAG) PR_TAG=$(PR_TAG) docker compose up -d --remove-orphans

pull:      ## Pull the latest images
	@AR_TAG=$(AR_TAG) CS_TAG=$(CS_TAG) PR_TAG=$(PR_TAG) docker compose pull

down:      ## Stop the services
	@AR_TAG=$(AR_TAG) CS_TAG=$(CS_TAG) PR_TAG=$(PR_TAG) docker compose down

prune:     ## prune docker space
	@docker system prune -f --volumes

terraform-setup:  ## Set up the vms for the demo
	cd terraform && terraform init && (terraform import -var='vm_repeats=1' -var='vm_count=5' azurerm_resource_group.compliance_framework_demo_resource_group /subscriptions/$(AZURE_SUBSCRIPTION_ID)/resourceGroups/compliance-framework-demo-1 || true) && terraform apply -auto-approve -var='vm_repeats=1' -var='vm_count=5'

terraform-destroy:   ## Destroy the vms for the demo
	cd terraform && terraform destroy -target azurerm_subnet.compliance_framework_demo_subnet -target azurerm_virtual_network.compliance_framework_demo_virtual_network -target 'module.vm["0"].azurerm_network_interface.compliance_framework_demo_network_interface[0]' -target 'module.vm["0"].azurerm_network_interface.compliance_framework_demo_network_interface[1]' -target 'module.vm["0"].azurerm_virtual_machine.compliance_framework_demo_virtual_machine[1]' -target 'module.vm["0"].random_id.compliance_framework_demo_random_id' -auto-approve -var='vm_repeats=1' -var='vm_count=5'
