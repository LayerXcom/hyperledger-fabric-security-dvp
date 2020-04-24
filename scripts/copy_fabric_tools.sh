#!/bin/sh

echo
echo "=========== Copy fabric tools ==========="

set -eu

BIN_DIR=./docker-bin
mkdir -p $BIN_DIR
HLF_CA=hlf-ca
HLF_TOOLS=hlf-tools

docker run -d --name $HLF_CA hyperledger/fabric-ca
CONTAINER_ID=$(docker ps -aqf "name=${HLF_CA}")
docker cp $CONTAINER_ID:/usr/local/bin/fabric-ca-client $BIN_DIR/fabric-ca-client
docker rm -f $CONTAINER_ID

docker run -d --name $HLF_TOOLS hyperledger/fabric-tools
CONTAINER_ID=$(docker ps -aqf "name=${HLF_TOOLS}")
docker cp $CONTAINER_ID:/usr/local/bin/peer $BIN_DIR/peer
docker cp $CONTAINER_ID:/usr/local/bin/configtxgen $BIN_DIR/configtxgen
docker cp $CONTAINER_ID:/usr/local/bin/configtxlator $BIN_DIR/configtxlator
docker cp $CONTAINER_ID:/usr/bin/jq $BIN_DIR/jq
docker rm -f $CONTAINER_ID