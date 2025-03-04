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

## Using Makefile

First, specify your compose command:

```
export COMPOSE_COMMAND='docker compose'
export COMPOSE_COMMAND='podman-compose'
```

### Starting/Restarting All Services

Then, if you want to bring the services up (or restart):

```shell
# Running all services
make compose-restart
```

### Running Only Data Stores

There are cases where some services need to be excluded as you will work on them locally.

For example, when working on the Configuration API locally, you need mongo and nats, but will run the API
using `go run main.go`.

In such cases you can selectively run the services you need, after starting up the common ones.

```shell
# Run only the common external services
make common-only-restart
```

### Running agent daemons

This repository also contains examples of running agents in the `demo-agents` folder.

You can include these when running locally to populate the API and Data stores.

```shell
# Running the demo agent daemons plugin 
make agents-only-restart
```

## Access the Mongodb

1. Get a shell on the mongodb pod (eg by hitting 's' in k9s on the pod)

2. Run `mongosh`

3. Run `use cf` to select the Compliance Framework database

4. Run queries, eg:

`show tables`

`db.plan.findOne()`

`db.plan.find()`

Observations in the last 10 minutes:

```
db.plan.aggregate([
  {
    $unwind: "$results"
  },
  {
    $unwind: "$results.observations"
  },
  {
    $match: {
      "results.observations.collected": {
        $gte: new Date(new Date() - 10 * 60 * 1000)
      }
    }
  },
  {
    $project: {
      "observation": "$results.observations"
    }
  }
])
```

## Quickstart Gotchas

- There are known issues running MongoDB on non-AVX-supporting processors. In this event you will see this message in the mongodb-0 logs:

```
$ kubectl logs mongodb-0

WARNING: MongoDB 5.0+ requires a CPU with AVX support, and your current system does not appear to have that!
  see https://jira.mongodb.org/browse/SERVER-54407
  see also https://www.mongodb.com/community/forums/t/mongodb-5-0-cpu-intel-g4650-compatibility/116610/2
  see also https://github.com/docker-library/mongo/issues/485#issuecomment-891991814
```
