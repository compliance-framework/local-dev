# compliance-framework/infrastructure

This project helps setting up infrastructure for both local development and (soon) cloud development on kubernetes.

For now this is really a bunch of ugly bash scripts :) use cautiously.

# Quickstart

1. Make sure azure client variables are in shell:

```
export AZURE_CLIENT_ID=X
export AZURE_CLIENT_SECRET=X
export AZURE_TENANT_ID=X
```

2. `make up`
3. `make setup`
