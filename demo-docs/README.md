# Instructions on demoing specific features of continuous compliance

## Update your demo environment

> [!WARNING]
> Don't do this right before a demo. This will pull all the latest changes, and could break your demo environment if it was working before.

```shell
make compose-destroy # Destroy your environment and it's data
git pull origin main # Fetch the latest demo-able changes
make compose-pull # Pull all the latest images
./hack/local-shared/do up -d --build # Run everything, and rebuild the agent images
```

## Accessing the environment

http://localhost:8000 for the latest demoable UI.

## Specific demos
1. [SSH policies and compliance](./1.ssh-policy-enforcement.md)
