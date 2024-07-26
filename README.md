# Compliance-Framework Infrastructure Example

This project helps setting up infrastructure for local development.

It could be considered an example deployment as opposed to actually part of the working code.

These are the components that it sets-up:

- Configuration Service: This acts as the API and is the "brain" of the system

- Assessment Runtime: This is what interacts with the subjects of the assessment and gathers information in order to report back to the configuration service

- Plugin Registry: Whence the provider binaries are retrieved

- MongoDB: The persistent data store

- NATS: The message bus

Once the quickstart has been followed, there will be:

- A running instance of CF using `kind` and scanning on an Azure subscription (this must be setup externally)

- A check via ssh of an arbitary command's exit status

# Quickstart

1. Make you have [kind](https://kind.sigs.k8s.io/) installed.

1. Make sure azure client variables are set in a `.env` file (ignored by git) in the root folder of this repository **(NOTE _this example project uses Azure_ but CF is not Azure specific)**:

```zsh
export AZURE_SUBSCRIPTION_ID='[REPLACEME]'
export AZURE_CLIENT_ID='[REPLACEME]'
export AZURE_CLIENT_SECRET='[REPLACEME]'
export AZURE_TENANT_ID='[REPLACEME]'

export CF_SSH_USERNAME='[REPLACEME]'
export CF_SSH_PASSWORD='[REPLACEME]'
export CF_SSH_COMMAND='[REPLACEME]'
export CF_SSH_HOST='[REPLACEME]'
```

2. `make help` should give you commands to run to set up various scenarios. See especially `make k8s_restart`, designed to refresh the environment from scratch
