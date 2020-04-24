# !/bin/bash

echo
echo "=========== Boost "$1" peer ==========="

set -eu

. ./.env

ORG=$1
CA_HOST=$2
NODE=$3
PEER_ADMIN_ID=$4
ENROLL_SECRET=$5
LOCAL_MSP_DIR=$FABRIC_CFG_PATH/mspdir/$ORG/msp
################################################################################
#
#   Peerの設定と起動
#
################################################################################
# mspディレクトリの作成
mkdir -p ./nodes/$NODE/mspdir/$ORG/msp/admincerts
mkdir -p ./nodes/$NODE/mspdir/$ORG/msp/signcerts
mkdir -p ./nodes/$NODE/mspdir/$ORG/msp/cacerts

echo
echo "=========== Register "$PEER_ADMIN_ID" identity =========== "

# peer管理者として利用するIdentityをregister
docker-compose exec $CA fabric-ca-client register \
    -u http://$CA_HOST \
    --id.name $PEER_ADMIN_ID \
    --id.secret $ENROLL_SECRET \
    --id.attrs '"hf.Registrar.Roles=peer,client,admin"'

echo
echo "=========== Enroll "$PEER_ADMIN_ID" identity =========== "

# peerのアカウントをenroll
docker-compose run --rm \
    $NODE /docker-bin/fabric-ca-client enroll -u http://$PEER_ADMIN_ID:$ENROLL_SECRET@$CA_HOST -M $LOCAL_MSP_DIR

# MSPディレクトリにpeerのCAの証明書を配置
docker-compose run --rm \
    $NODE /docker-bin/fabric-ca-client getcacert -u $CA_HOST -M $LOCAL_MSP_DIR

# 先程発行したIdentityをpeerの管理者Identityとして扱いたいので発行した証明書をadmincertsに配置
cp ./nodes/$NODE/mspdir/$ORG/msp/signcerts/*.pem ./nodes/$NODE/mspdir/$ORG/msp/admincerts/

# Peerの設定ファイルを配置
cp ./configs/common/$CONFIG_FILE_NAME ./nodes/$NODE/$CONFIG_FILE_NAME

# peer起動
docker-compose up -d $NODE