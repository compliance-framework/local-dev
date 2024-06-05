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

AZURE_SUBSCRIPTION_ID := $(shell . ./sourceme; echo $$AZURE_SUBSCRIPTION_ID)
AZURE_CLIENT_ID       := $(shell . ./sourceme; echo $$AZURE_CLIENT_ID)
AZURE_TENANT_ID       := $(shell . ./sourceme; echo $${AZURE_TENANT_ID})
AZURE_CLIENT_SECRET   := $(shell . ./sourceme; echo $$AZURE_CLIENT_SECRET)


help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

restart: down setup

setup: up  ## Set up a default scenario for CF
	bash hack/setup.sh

up:    ## Bring up the services
	@AZURE_SUBSCRIPTION_ID=$(AZURE_SUBSCRIPTION_ID) AZURE_TENANT_ID=$(AZURE_TENANT_ID) AZURE_CLIENT_ID=$(AZURE_CLIENT_ID) AZURE_CLIENT_SECRET=$(AZURE_CLIENT_SECRET) AR_TAG=$(AR_TAG) CS_TAG=$(CS_TAG) docker compose up -d

pull:      ## Pull the latest images
	AR_TAG=$(AR_TAG) CS_TAG=$(CS_TAG) docker compose pull

down:      ## Stop the services
	AR_TAG=$(AR_TAG) CS_TAG=$(CS_TAG) docker compose down
