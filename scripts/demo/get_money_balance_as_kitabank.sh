#!/bin/bash

. ./.env

echo
echo "=========== kitabankからinvestor01のお金残高を確認 =========== "
export GET_MONEY_INFO=$(echo -n "{\"organization\":\"MinatoBank\",\"identity\":\"investor01\"}" | base64 | tr -d \\n)
docker-compose run --rm \
    $KITABANK_PEER peer chaincode invoke -C $CH -n $CC_MONEY -c '{"Args":["getBalance"]}' --transient "{\"getMoneyBalance\":\"$GET_MONEY_INFO\"}"