#!/bin/bash

. ./.env

echo
echo "=========== investor01の証券残高 =========== "
docker-compose run --rm \
    cc-builder peer chaincode invoke -C $CH -n $CC_SECURITY_MANAGER -c '{"Args":["getBalance", "{\"securityId\":\"security1\",\"organization\":\"MinatoBank\",\"identity\":\"investor01\"}"]}'

echo
echo "=========== investor02の証券残高 =========== "
docker-compose run --rm \
    cc-builder peer chaincode invoke -C $CH -n $CC_SECURITY_MANAGER -c '{"Args":["getBalance", "{\"securityId\":\"security1\",\"organization\":\"MinatoBank\",\"identity\":\"investor02\"}"]}'

echo
echo "=========== investor03の証券残高 =========== "
docker-compose run --rm \
    cc-builder peer chaincode invoke -C $CH -n $CC_SECURITY_MANAGER -c '{"Args":["getBalance", "{\"securityId\":\"security1\",\"organization\":\"MinatoBank\",\"identity\":\"investor03\"}"]}'