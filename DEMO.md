## Pre-work
Azure subscription created:
  ian-compliance-framework, under ian.miell@container-solutions.com
App registration created
  ian-compliance-framework
App needs to be given perms on the subscription via IAM on the subscription.

To get the login details:

```
az ad sp create-for-rbac --name ian-compliance-framework -o table
AppId                                 DisplayName               Password                                  Tenant
------------------------------------  ------------------------  ----------------------------------------  ------------------------------------
0443096c-6f22-4851-8c4f-d4da9e2e9683  ian-compliance-framework  xxxxxxxxxxxxxxxxxxx                       2ed1d494-6c5a-4c5d-aa24-479446fb844d
```

```
AppId = AZURE_CLIENT_ID
Password = AZURE_CLIENT_SECRET
Tenant = AZURE_TENANT_ID
```

```
export AZURE_SUBSCRIPTION_ID=99a25d6b-fbbb-4f83-9c0a-f67f8e1446ad
export AZURE_CLIENT_ID=0443096c-6f22-4851-8c4f-d4da9e2e9683
export AZURE_TENANT_ID=2ed1d494-6c5a-4c5d-aa24-479446fb844d
export AZURE_CLIENT_SECRET=xxxxxxxxxxxxxxxx
```

These details are placed in `sourceme`


## For demo

Create two VMS, one with dataclassification tag within the app registration you've created

`make stop && source sourceme && make up && make setup && docker logs infrastructure-assessment-runtime-1 -f`



### Preparation!
- Create (or reuse) resource group (compliance-framework-demo-1)
- Create two VMS
  - Standard Security Type, with spot discount, username imiell/CFhh1!
    - 1) compliant
      - with dataclassification tag: dataclassification/internal (go to Tags tab before creating)
    - 2) uncompliant
      - with no dataclassification

### Run up!
```
cd ~/git/compliance-framework/infrastructure
make stop && source sourceme && make up && make setup
docker logs infrastructure-assessment-runtime-1 -f
```





### Preparation!
Talk over:
  Go to: http://localhost:8080/swagger/index.html

  Run:
    # This is the key one:
    curl http://localhost:8080/api/plan/todo/results/todo/observations | jq . | less
    # Don't understand how these numbers come out - TODO look at code
    curl http://localhost:8080/api/plan/todo/results/todo/compliance-over-time | jq . | less
    # Don't understand this - how do controls relate to target and compliance?
    curl http://localhost:8080/api/plan/todo/results/todo/compliance-status-by-targets | jq . | less
    # null?
    curl http://localhost:8080/api/plan/todo/results/todo/findings | jq . | less

Front end: http://localhost:8081/

https://pages.nist.gov/OSCAL/

```
docker exec -ti infrastructure-mongodb-1 bash
mongosh
use cf
show tables
db.plan.find()
```
