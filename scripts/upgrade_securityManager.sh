#!/bin/bash

set -eu

. ./.env
. ./scripts/utils/copy_msp.sh

CC_VER=$1
WORKING_DIR=./nodes/cc-builder
CC_BASE_PATH=matilda/chaincodes

mkdir -p $WORKING_DIR
cp ./configs/common/core.yaml $WORKING_DIR/core.yaml

copy_msp_including_keystore ./nodes/${PLATFORM_PEER}/mspdir/${PLATFORM_MSPID}/msp $WORKING_DIR/mspdir/${PLATFORM_MSPID}/msp

# 本来は手動で上げる ex) 1.0, 1.1, ...etc
# VERSION=$(date +%s)
# 他のPeerでもChaincodeをInstallする。なのでバージョンを合わせるため.envにVER環境変数を用意してそれをVERSION変数に代入する
VERSION=$CC_VER
CDIR=$(pwd)

# install organization chaincode to all-ch on platform-peer1
docker-compose run --rm \
    cc-builder peer chaincode install -n $CC_SECURITY_MANAGER -v $VERSION -p $CC_BASE_PATH/security_manager
docker-compose run --rm \
    cc-builder peer chaincode install -n $CC_MONEY -v $VERSION -p $CC_BASE_PATH/money

# install organization chaincode to all-ch on minatobank-peer1
docker-compose run --rm \
    -v ${CDIR}/nodes/${MINATOBANK_PEER}/mspdir/${MINATOBANK_MSPID}/msp:${FABRIC_CFG_PATH}/mspdir/${MINATOBANK_MSPID}/msp \
    -e "CORE_PEER_ADDRESS=${MINATOBANK_PEER}:${MINATOBANK_PEER_PORT}" \
    -e "CORE_PEER_LOCALMSPID=${MINATOBANK_MSPID}" \
    -e "CORE_PEER_MSPCONFIGPATH=mspdir/${MINATOBANK_MSPID}/msp" \
    cc-builder peer chaincode install -n $CC_SECURITY_MANAGER -v $VERSION -p $CC_BASE_PATH/security_manager

docker-compose run --rm \
    -v ${CDIR}/nodes/${MINATOBANK_PEER}/mspdir/${MINATOBANK_MSPID}/msp:${FABRIC_CFG_PATH}/mspdir/${MINATOBANK_MSPID}/msp \
    -e "CORE_PEER_ADDRESS=${MINATOBANK_PEER}:${MINATOBANK_PEER_PORT}" \
    -e "CORE_PEER_LOCALMSPID=${MINATOBANK_MSPID}" \
    -e "CORE_PEER_MSPCONFIGPATH=mspdir/${MINATOBANK_MSPID}/msp" \
    cc-builder peer chaincode install -n $CC_MONEY -v $VERSION -p $CC_BASE_PATH/money

# install organization chaincode to all-ch on kitabank-peer1
docker-compose run --rm \
    -v ${CDIR}/nodes/${KITABANK_PEER}/mspdir/${KITABANK_MSPID}/msp:${FABRIC_CFG_PATH}/mspdir/${KITABANK_MSPID}/msp \
    -e "CORE_PEER_ADDRESS=${KITABANK_PEER}:${KITABANK_PEER_PORT}" \
    -e "CORE_PEER_LOCALMSPID=${KITABANK_MSPID}" \
    -e "CORE_PEER_MSPCONFIGPATH=mspdir/${KITABANK_MSPID}/msp" \
    cc-builder peer chaincode install -n $CC_SECURITY_MANAGER -v $VERSION -p $CC_BASE_PATH/security_manager

docker-compose run --rm \
    -v ${CDIR}/nodes/${KITABANK_PEER}/mspdir/${KITABANK_MSPID}/msp:${FABRIC_CFG_PATH}/mspdir/${KITABANK_MSPID}/msp \
    -e "CORE_PEER_ADDRESS=${KITABANK_PEER}:${KITABANK_PEER_PORT}" \
    -e "CORE_PEER_LOCALMSPID=${KITABANK_MSPID}" \
    -e "CORE_PEER_MSPCONFIGPATH=mspdir/${KITABANK_MSPID}/msp" \
    cc-builder peer chaincode install -n $CC_MONEY -v $VERSION -p $CC_BASE_PATH/money

# upgrade $CC_SECURITY_MANAGER in all-ch
docker-compose run --rm \
    cc-builder peer chaincode upgrade -n $CC_SECURITY_MANAGER -v $VERSION -c '{"Args":[]}' -C all-ch --collections-config /opt/gopath/src/private_config/collections_config.json

# upgrade money in all-ch
docker-compose run --rm \
    cc-builder peer chaincode upgrade -n $CC_MONEY -v $VERSION -c '{"Args":[]}' -C all-ch --collections-config /opt/gopath/src/private_config/collections_config.json

# platform-peer1でchaincodeのinstallを確認
docker-compose run --rm \
    cc-builder peer chaincode list --installed

# platform-peer1でchaincodeのinstantiateを確認
docker-compose run --rm \
    cc-builder peer chaincode list --instantiated -C all-ch
