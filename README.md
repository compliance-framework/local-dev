# Compliance-Framework Infrastructure Example

This project helps setting up infrastructure for local development.

It could be considered an example deployment as opposed to actually part of the working code.

These are the components that it sets-up:

- Configuration Service: This acts as the API and is the "brain" of the system

- Assessment Runtime: This is what interacts with the subjects of the assessment and gathers information in order to report back to the configuration service

- Plugin Registry: Whence the provider binaries are retrieved

- MongoDB: The persistent data store

Once the quickstart has been followed, there will be:

- A running instance of CF using `kind` and scanning on an Azure subscription (this must be setup externally)

- A check via ssh of an arbitary command's exit status

# Quickstart

## Set environment values

First step, is to set the environment values for the pieces you'll use.

Copy the .env.example file to a .env file and fill out the field you are interested in.

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

### Uploading Catalogs

```shell
curl --request POST \
  --url http://localhost:8080/api/catalogs \
  --header 'Content-Type: multipart/form-data' \
  --form file=@./catalogs/SAMA_CSF_1.0_catalog.json

curl --request POST \
  --url http://localhost:8080/api/catalogs \
  --header 'Content-Type: multipart/form-data' \
  --form file=@./catalogs/SAMA_ITGF_1.0_catalog.json

curl --request POST \
  --url http://localhost:8080/api/catalogs \
  --header 'Content-Type: multipart/form-data' \
  --form file=@./catalogs/NIST_SP-800-53_rev5_catalog.json
```

### Azure setup

#### Azure Setup Prerequisites

- `az` command

- Go to onePassword and get azure creds (`Azure CCF Login`)

### Azure Setup Steps

- Copy the creds to .env for export

- `make azure-login`

If you wish to to create them from scratch and provision elsewhere:

- `make azure-create-service-principal`

- take response from this and export new creds

- `make azure-login`

### AWS Setup

#### AWS Setup Prerequisites

- `aws` command

- `aws` account with administrator access

#### AWS Setup Steps

1. Create access keys for your AWS account.

2. Add to the file `~/.aws/configure`:

```
[profile ccf-demo-1]
region=us-east-1
```

3. Add to the file `~/.aws/credentials`:

```
[ccf-demo-1]
aws_access_key_id=<<YOUR KEYID>>
aws_secret_access_key=<<YOUR KEY>>
```

4. Get the creds into the .env file

```
make aws-get-sts
```

5. Set up env variables

```
source <(grep '^[A-Z_]' .env | sed 's/^/export /')
```

6. Set up Terraform

```
make aws-tf
```

### Running Only Data Stores

There are cases where some services need to be excluded as you will work on them locally.

For example, when working on the Configuration API locally, you need mongo, but will run the API
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
