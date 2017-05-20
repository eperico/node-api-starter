#!/bin/bash
BRANCH=$1
SERVICE=$2

if [[ -z "$1" ]]; then
  BRANCH=master
else
  BRANCH=$1
fi

set -e
. ~/.nvm/nvm.sh

echo "STOPING THE SERVICE"
pm2 stop $SERVICE

echo "CHECKOUT" $BRANCH "branch"
echo "GET THE LATEST VERSION"
cd /home/ubuntu/web/sites/node-api-starter
git reset --hard origin/master
git fetch origin
git pull origin $BRANCH
git merge --no-edit origin/$BRANCH

echo "NPM INSTALL"
nvm use
npm install

echo "STARTING THE SERVICE"
pm2 start $SERVICE
