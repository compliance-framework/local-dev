#!/bin/bash
set -e
if [ -d "configuration-service" ]; then
  echo "configuration-service exists"
else
  echo "Cloning configuration-service"
  git clone git@github.com:compliance-framework/configuration-service.git
fi
if [ -d "assessment-runtime" ]; then
  echo "assessment-runtime exists"
else
  echo "Cloning assessment-runtime"
  git clone git@github.com:compliance-framework/assessment-runtime.git
fi
if [ -d "portal" ]; then
  echo "portal exists"
else
  echo "Cloning portal"
  git clone git@github.com:compliance-framework/portal.git
fi

branch=$CONFIG_SERVICE_BRANCH
if [ -z "$branch" ]; then branch="main"; fi
cd configuration-service
git fetch
git checkout "$branch"
git pull origin "$branch"
cd -

branch=$ASSESSMENT_RUNTIME_BRANCH
if [ -z "$branch" ]; then branch="main"; fi
cd assessment-runtime
git fetch
git checkout "$branch"
git pull origin "$branch"
cd -

branch=$PORTAL_BRANCH
if [ -z "$branch" ]; then branch="main"; fi
cd portal
git fetch
git checkout "$branch"
git pull origin "$branch"
cd -
