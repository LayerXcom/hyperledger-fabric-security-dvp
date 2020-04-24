#!/bin/bash

. ./.env

echo
echo "=========== kitabankからinvestor01のお金残高を確認 =========== "
docker-compose run --rm \
    $KITABANK_PEER peer chaincode invoke -C $CH -n $CC_MONEY -c '{"Args":["getBalance", "{\"organization\":\"MinatoBank\",\"identity\":\"investor01\"}"]}'
