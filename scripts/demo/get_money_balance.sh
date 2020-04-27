#!/bin/bash

. ./.env

NODE=$MINATOBANK_PEER

echo
echo "=========== layerxのお金残高 =========== "
export GET_MONEY_INFO=$(echo -n "{\"organization\":\"Platform\",\"identity\":\"layerx\"}" | base64 | tr -d \\n)
docker-compose run --rm \
    $PLATFORM_PEER peer chaincode invoke -C $CH -n $CC_MONEY -c '{"Args":["getBalance"]}' --transient "{\"getMoneyBalance\":\"$GET_MONEY_INFO\"}"

# Money残高確認(MINATOBANK)
# investor01
echo
echo "=========== investor01のお金残高 =========== "
export GET_MONEY_INFO=$(echo -n "{\"organization\":\"MinatoBank\",\"identity\":\"investor01\"}" | base64 | tr -d \\n)
docker-compose run --rm \
    $NODE peer chaincode invoke -C $CH -n $CC_MONEY -c '{"Args":["getBalance"]}' --transient "{\"getMoneyBalance\":\"$GET_MONEY_INFO\"}"

# investor02
echo
echo "=========== investor02のお金残高 =========== "
export GET_MONEY_INFO=$(echo -n "{\"organization\":\"MinatoBank\",\"identity\":\"investor02\"}" | base64 | tr -d \\n)
docker-compose run --rm \
    $NODE peer chaincode invoke -C $CH -n $CC_MONEY -c '{"Args":["getBalance"]}' --transient "{\"getMoneyBalance\":\"$GET_MONEY_INFO\"}"

# investor03
echo
echo "=========== investor03のお金残高 =========== "
export GET_MONEY_INFO=$(echo -n "{\"organization\":\"MinatoBank\",\"identity\":\"investor03\"}" | base64 | tr -d \\n)
docker-compose run --rm \
    $NODE peer chaincode invoke -C $CH -n $CC_MONEY -c '{"Args":["getBalance"]}' --transient "{\"getMoneyBalance\":\"$GET_MONEY_INFO\"}"