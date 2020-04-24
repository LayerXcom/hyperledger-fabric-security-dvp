# !/bin/bash

echo
echo "=========== Setup orderer ==========="

set -eu

. ./.env

MSPID=$ORDERER
NODE=$MSPID
ORDERER_ADMIN_ID=orderer_admin
ENROLL_SECRET=password
LOCAL_MSP_DIR=$FABRIC_CFG_PATH/mspdir/$MSPID/msp

# mspディレクトリの作成
mkdir -p ./nodes/$NODE/mspdir/$MSPID/msp/admincerts
mkdir -p ./nodes/$NODE/mspdir/$MSPID/msp/signcerts
mkdir -p ./nodes/$NODE/mspdir/$MSPID/msp/cacerts

echo
echo "=========== Register "$ORDERER_ADMIN_ID" identity =========== "

# ordererの管理者として利用するIdentityをregister
docker-compose run --rm \
    $ORDERER_CA fabric-ca-client register \
    -u http://$ORDERER_CA:$ORDERER_CA_PORT \
    --id.name $ORDERER_ADMIN_ID \
    --id.secret $ENROLL_SECRET \
    --id.attrs '"hf.Registrar.Roles=peer,client,admin,orderer"'

echo
echo "=========== Enroll "$ORDERER_ADMIN_ID" identity =========== "

# ordererのidentityをenroll。鍵がordererコンテナで生成され、それを元にCAサーバーで証明書が発行される
docker-compose run --rm \
    $NODE /docker-bin/fabric-ca-client enroll -u http://$ORDERER_ADMIN_ID:$ENROLL_SECRET@$ORDERER_CA:$ORDERER_CA_PORT -M $LOCAL_MSP_DIR

# Local MSPにCAサーバー本体の証明書を置く。
docker-compose run --rm \
    $NODE /docker-bin/fabric-ca-client getcacert -u $ORDERER_CA:$ORDERER_CA_PORT -M $LOCAL_MSP_DIR

# MSPディレクトリのadmincertsに先程enrollで発行した証明書を配置（＝管理者Identityとみなされる）
cp ./nodes/$NODE/mspdir/$MSPID/msp/signcerts/*.pem ./nodes/$NODE/mspdir/$MSPID/msp/admincerts/