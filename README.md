# compliance-framework/infrastructure

This project helps setting up infrastructure for both local development and (soon) cloud development on kubernetes.

For now this is really a bunch of ugly bash scripts :) use cautiously.

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
