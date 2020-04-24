# !/bin/bash

# usage:
# docker-compose run --rm minatobank-peer1 bash /scripts/add_identity.sh minatobank investor01 password minatobank-ca:7064

set -eu

export FABRIC_CFG_PATH=/etc/hyperledger/fabric

ORG=$1
IDENTITY_NAME=$2
IDENTITY_SECRET=$3
CA_HOST=$4

# 追加するIdentityの証明書や鍵などは一旦仮でidentities/{Identity名}のところに保存する
IDENTITY_MSP_DIR=$FABRIC_CFG_PATH/mspdir/$ORG/msp/identities/$IDENTITY_NAME
mkdir -p $IDENTITY_MSP_DIR

echo
echo "=========== Register "$IDENTITY_NAME" identity ==========="
# minatobank-peer1のIdentityでIdentity register
/docker-bin/fabric-ca-client register \
    -u http://$CA_HOST \
    --id.name $IDENTITY_NAME \
    --id.secret $IDENTITY_SECRET \
    --mspdir $FABRIC_CFG_PATH/mspdir/$ORG/msp

echo
echo "=========== Enroll "$IDENTITY_NAME" identity ==========="
# minatobank-peer1のIdentityでIdentity enroll
/docker-bin/fabric-ca-client enroll \
    -u http://$IDENTITY_NAME:$IDENTITY_SECRET@$CA_HOST \
    -M $IDENTITY_MSP_DIR