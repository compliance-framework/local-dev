#! /bin/bash
set -e
if [ -d "configuration-service" ]; then
 echo "configuration-ervice does exist."
else 
 echo "Clonning configuration-service";
 git clone git@github.com:compliance-framework/configuration-service.git
fi
if [ -d "assessment-runtime" ]; then
 echo "assessment-runtime does exist."
else
 echo "Clonning assessment-runtime"
 git clone git@github.com:compliance-framework/assessment-runtime.git
fi
if [ -d "portal" ]; then
 echo "portal does exist."
else 
 echo "Clonning portal"
 git clone git@github.com:compliance-framework/portal.git
fi

branch=$CONFIG_SERVICE_BRANCH
if [ -z $branch ]; then branch="main"; fi
cd configuration-service; git checkout $branch; git pull origin $branch; cd -

branch=$ASSESSMENT_RUNTIME_BRANCH
if [ -z $branch ]; then branch="main"; fi
cd assessment-runtime; git checkout $branch; git pull origin $branch; cd -

branch=$PORTAL_BRANCH
if [ -z $branch ]; then branch="feature/assessment-result"; fi
cd portal; git checkout $branch; git pull origin $branch; cd -
