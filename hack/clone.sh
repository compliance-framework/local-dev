#!/bin/bash
set -e

for repo in "configuration-service" "assessment-runtime" "portal"; do
  if [ -d "$repo" ]; then
    echo "$repo exists"
  else
    echo "Cloning $repo"
    git clone git@github.com:compliance-framework/$repo.git
  fi
done

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
