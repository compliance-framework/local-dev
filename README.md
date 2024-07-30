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

These instructions will get you going quickly with two plugins (azure and ssh).

1. Make you have [KIND](https://kind.sigs.k8s.io/) installed.

This sets up the Kubernetes cluster you will run Compliance Framework's components on.

1. Download the latest version of `cfctl` from the [releases](https://github.com/compliance-framework/cfctl/releases) page, and place in your `PATH`, eg `mv cfctl /usr/local/bin`

2. Make sure azure client variables are set in a `.env` file (ignored by git) in the root folder of this repository **(NOTE _this example project uses Azure_ but CF is not Azure specific)**:

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

`CF_SSH_COMMAND`

Optionally, you can set `CF_SSH_PORT` to a port other than the default (`22`) if your server uses a non-standard port.

3. Source the `.env` file

`source .env`

4. Initialise the kind server

`make kind_cluster_up`

This will bring up the KIND cluster.

5. Start up the compliance framework

`make k8s_up`

This brings up the pods and services that make up the CF cluster, and the persistent host disk that means that data is kept between `make k8s_restart`s.

6. (Optional) Set up the azure plugin

`make azure-vm-tag-setup`

7. (Optional) Set up the ssh plugin

`make ssh-setup`

8. (Optional) Install [k9s](https://k9scli.io/)

9. Run the demo script

`./demo.sh`

10. Interact with the demo script

You can run the various commands to interact with the server, eg

`ga` - show the graph of observations and findings

`gao` - get all observations

`gaf` - get all findings

You may need to wait a minute or so for results to start coming in.

`k9s` - starts a k9s window (assuming you have it installed)
