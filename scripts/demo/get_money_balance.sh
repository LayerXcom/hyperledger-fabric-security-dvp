#!/bin/bash

. ./.env

NODE=$MINATOBANK_PEER

echo
echo "=========== layerxのお金残高 =========== "
docker-compose run --rm \
    $PLATFORM_PEER peer chaincode invoke -C $CH -n $CC_MONEY -c '{"Args":["getBalance", "{\"organization\":\"Platform\",\"identity\":\"layerx\"}"]}'

# Money残高確認(MINATOBANK)
# investor01
echo
echo "=========== investor01のお金残高 =========== "
docker-compose run --rm \
    $NODE peer chaincode invoke -C $CH -n $CC_MONEY -c '{"Args":["getBalance", "{\"organization\":\"MinatoBank\",\"identity\":\"investor01\"}"]}'

echo
echo "=========== investor02のお金残高 =========== "
# investor02
docker-compose run --rm \
    $NODE peer chaincode invoke -C $CH -n $CC_MONEY -c '{"Args":["getBalance", "{\"organization\":\"MinatoBank\",\"identity\":\"investor02\"}"]}'

echo
echo "=========== investor03のお金残高 =========== "
# investor03
docker-compose run --rm \
    $NODE peer chaincode invoke -C $CH -n $CC_MONEY -c '{"Args":["getBalance", "{\"organization\":\"MinatoBank\",\"identity\":\"investor03\"}"]}'