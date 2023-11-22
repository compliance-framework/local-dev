# compliance-framework/infrastructure

This project helps setting up infrastructure for both local development and (soon) cloud development on kubernetes.

It could be considered an example deployment as opposed to actually part of the working code.

There are three main components that it sets up:

- Portal: this is the Frontend GUI.
- Configuration Service: This acts as the API and is the "brain".
- Assessment Runtime: This is what interacts with the cloud providers and gathers information in order to report back to configuration service.

In a real world deployment of CF, teams would likely write their own version of this repo and deploy it to whatever infrastructure they preferred to work with as opposed to just using docker-compose.

# Quickstart

1. Make sure you have a docker-compatible socket environment set up with a functioning CLI, in addition, docker-compose.
1. Make sure azure client variables are set:

```zsh
export AZURE_CLIENT_ID="[REPLACEME]"
export AZURE_CLIENT_SECRET="[REPLACEME]"
export AZURE_TENANT_ID="[REPLACEME]"
```

2. `make up` to checkout/update repos, build all the containers and spin them up
3. `make setup` should populate the data
