#!/bin/bash

echo
echo "============================================ "
echo "=========== Stop matilda network =========== "
echo "============================================ "
echo

set -e

rm -rf nodes && docker-compose down && docker rm -f $(docker ps -aq)

# Chaincode用コンテナイメージ全削除
sleep 3

echo
echo "=========== remove chaincode docker images =========== "
TARGET='peer1-securitymanager|money-1'
docker images | grep -E $TARGET | xargs docker rmi
