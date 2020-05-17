#!/bin/bash

. ./.env

echo
echo "=========== investor01の証券残高 =========== "
export GET_SECURITY_INFO=$(echo -n "{\"securityId\":\"security1\",\"organization\":\"MinatoBank\",\"identity\":\"investor01\"}" | base64 | tr -d \\n)
docker-compose run --rm \
    cc-builder peer chaincode invoke -C $CH -n $CC_SECURITY_MANAGER -c '{"Args":["getBalance"]}' --transient "{\"getSecurityBalance\":\"$GET_SECURITY_INFO\"}"

echo
echo "=========== investor02の証券残高 =========== "
export GET_SECURITY_INFO=$(echo -n "{\"securityId\":\"security1\",\"organization\":\"MinatoBank\",\"identity\":\"investor02\"}" | base64 | tr -d \\n)
docker-compose run --rm \
    cc-builder peer chaincode invoke -C $CH -n $CC_SECURITY_MANAGER -c '{"Args":["getBalance"]}' --transient "{\"getSecurityBalance\":\"$GET_SECURITY_INFO\"}"

echo
echo "=========== investor03の証券残高 =========== "
export GET_SECURITY_INFO=$(echo -n "{\"securityId\":\"security1\",\"organization\":\"MinatoBank\",\"identity\":\"investor03\"}" | base64 | tr -d \\n)
docker-compose run --rm \
    cc-builder peer chaincode invoke -C $CH -n $CC_SECURITY_MANAGER -c '{"Args":["getBalance"]}' --transient "{\"getSecurityBalance\":\"$GET_SECURITY_INFO\"}"