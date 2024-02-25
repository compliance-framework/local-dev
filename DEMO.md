Azure subscription created:
  ian-compliance-framework, under ian.miell@container-solutions.com

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
