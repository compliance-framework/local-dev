# Chris's local

This script makes it easier for Chris to work with local compose files. Use it to your hearts content. 

```shell
# Run all of the services. Nats + Mongo + API + Local SSH Agent
./hack/local-chris/do start_all

# Start API. No agents. Useful when developing agents. 
./hack/local-chris/do start_api

# Start Agents. No API. Useful when working on the API. 
./hack/local-chris/do start_agents

# Run compose commands like exec or logs 
./hack/local-chris/do logs configuration-service

# Stop all running services
./hack/local-chris/do stop
```
