#!/bin/bash

. ./.env

################################################################################
#
#   init
#
################################################################################

# minatobank投資家登録
ORG=$MINATOBANK_MSPID
MINATOBANK_CA_HOST=$MINATOBANK_CA:$MINATOBANK_CA_PORT
NODE=$MINATOBANK_PEER
IDENTITY_PASSWORD=password

# 投資家Identity登録(MINATOBANK)
echo
echo "=========== investor01 identity登録 =========== "
# investor01
docker-compose run --rm \
    $NODE bash /scripts/add_identity.sh $ORG investor01 $IDENTITY_PASSWORD $MINATOBANK_CA_HOST

echo
echo "=========== investor02 identity登録 =========== "
# investor02
docker-compose run --rm \
    $NODE bash /scripts/add_identity.sh $ORG investor02 $IDENTITY_PASSWORD $MINATOBANK_CA_HOST

echo
echo "=========== investor03 identity登録 =========== "
# investor03
docker-compose run --rm \
    $NODE bash /scripts/add_identity.sh $ORG investor03 $IDENTITY_PASSWORD $MINATOBANK_CA_HOST

echo
echo "=========== layerx(0) =========== "
# layerx(platform)
export MINT_MONEY_INFO=$(echo -n "{\"amount\":\"0\",\"organization\":\"Platform\",\"identity\":\"layerx\"}" | base64 | tr -d \\n)
docker-compose run --rm \
    cc-builder peer chaincode invoke -C $CH -n $CC_MONEY -c '{"Args":["mintMoney"]}' --transient "{\"mintMoney\":\"$MINT_MONEY_INFO\"}"

echo
echo "=========== investor01の口座初期設定(100000000000) =========== "
# investor01(MINATOBANK)
export MINT_MONEY_INFO=$(echo -n "{\"amount\":\"100000000000\",\"organization\":\"MinatoBank\",\"identity\":\"investor01\"}" | base64 | tr -d \\n)
docker-compose run --rm \
    cc-builder peer chaincode invoke -C $CH -n $CC_MONEY -c '{"Args":["mintMoney"]}' --transient "{\"mintMoney\":\"$MINT_MONEY_INFO\"}"

echo
echo "=========== investor02の口座初期設定(100000000000) =========== "
# investor02(MINATOBANK)
export MINT_MONEY_INFO=$(echo -n "{\"amount\":\"100000000000\",\"organization\":\"MinatoBank\",\"identity\":\"investor02\"}" | base64 | tr -d \\n)
docker-compose run --rm \
    cc-builder peer chaincode invoke -C $CH -n $CC_MONEY -c '{"Args":["mintMoney"]}' --transient "{\"mintMoney\":\"$MINT_MONEY_INFO\"}"

echo
echo "=========== investor03の口座初期設定(200000000000) =========== "
# investor03(MINATOBANK)
export MINT_MONEY_INFO=$(echo -n "{\"amount\":\"200000000000\",\"organization\":\"MinatoBank\",\"identity\":\"investor03\"}" | base64 | tr -d \\n)
docker-compose run --rm \
    cc-builder peer chaincode invoke -C $CH -n $CC_MONEY -c '{"Args":["mintMoney"]}' --transient "{\"mintMoney\":\"$MINT_MONEY_INFO\"}"