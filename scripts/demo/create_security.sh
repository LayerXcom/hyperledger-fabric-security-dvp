#!/bin/bash

. ./.env

NODE=$MINATOBANK_PEER

echo
echo "========= 証券登録(発行数: 100, １口当たり価格: 10000) =========== "
docker-compose run \
    $NODE peer chaincode invoke -C $CH -n $CC_SECURITY_MANAGER -c '{"Args":["createSecurity", "{\"uuid\":\"security1\",\"securityInfo\":{\"name\":\"OneMilionSecurity\",\"issuer\":\"layerx\",\"units\":\"100\",\"price\":\"10000\"}}"]}'

sleep 1

echo
echo "=========== 証券一覧取得 =========== "
docker-compose run --rm \
   cc-builder peer chaincode invoke -C $CH -n $CC_SECURITY_MANAGER -c '{"Args":["queryAllSecurities"]}'

sleep 1

echo
echo "=========== investor01の証券購入量を登録(40) =========== "
# 証券購入登録(investor01)
docker-compose run --rm \
    $NODE peer chaincode invoke -C $CH -n $CC_SECURITY_MANAGER -c '{"Args":["reservePurchase", "{\"securityId\":\"security1\",\"organization\":\"MinatoBank\",\"investorId\":\"investor01\",\"units\":\"40\"}"]}'

echo
echo "=========== investor02の証券購入量を登録(50) =========== "
# 証券購入登録(investor02)
docker-compose run --rm \
    $NODE peer chaincode invoke -C $CH -n $CC_SECURITY_MANAGER -c '{"Args":["reservePurchase", "{\"securityId\":\"security1\",\"organization\":\"MinatoBank\",\"investorId\":\"investor02\",\"units\":\"50\"}"]}'

echo
echo "=========== investor03の証券購入量を登録(10) =========== "
# 証券購入登録(investor03)
docker-compose run --rm \
    $NODE peer chaincode invoke -C $CH -n $CC_SECURITY_MANAGER -c '{"Args":["reservePurchase", "{\"securityId\":\"security1\",\"organization\":\"MinatoBank\",\"investorId\":\"investor03\",\"units\":\"10\"}"]}'