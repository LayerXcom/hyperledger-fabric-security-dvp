#!/bin/bash

. ./.env

echo
echo "=========== Setup network =========== "

set -eu

# setup orderer
. ./scripts/setup_orderer.sh

# setup platform
. ./scripts/setup_platform.sh

ORG=$PLATFORM_MSPID
# platform/mspディレクトリ作成
mkdir -p ./nodes/orderer/mspdir/${ORG}/msp

# コンソーシアム作成にはplatform-peer1のCAのroot証明書をordererに食わせる必要あり(genesis block生成のため)
cp -r ./nodes/${PLATFORM_PEER}/mspdir/${ORG}/msp/cacerts ./nodes/${ORDERER}/mspdir/${ORG}/msp
# チャネル作成にはordererにplatform-peer1のadmincertsを食わせる必要あり(原因はまだ)
# issue: https://github.com/LayerXcom/matilda/issues/11
cp -r ./nodes/${PLATFORM_PEER}/mspdir/${ORG}/msp/admincerts ./nodes/${ORDERER}/mspdir/${ORG}/msp

################################################################################
#
#   Genesisブロック生成とorderer起動
#
################################################################################
echo
echo "=========== Creating genesis block ==========="
docker-compose run --rm \
    $ORDERER /docker-bin/configtxgen -profile OrdererGenesis -outputBlock $FABRIC_CFG_PATH/genesis.block
docker-compose up -d $ORDERER

################################################################################
#
#   チャネル作成
#
################################################################################
CONFIG_TX=$FABRIC_CFG_PATH/$CH.tx
CONFIG_BLOCK=$FABRIC_CFG_PATH/$CH.block
NODE=$PLATFORM_PEER
# channel用TX生成
docker-compose run --rm \
    $NODE $DOCKER_BIN_PATH/configtxgen -outputCreateChannelTx $CONFIG_TX -profile $CH -channelID $CH

echo
echo "=========== Creating channel: "$CH" ==========="
# platform-peer1でchannel作成
docker-compose run --rm \
    $NODE peer channel create -o $ORDERER:$ORDERER_PORT -c $CH -f $CONFIG_TX --outputBlock $CONFIG_BLOCK

################################################################################
#
#   チャネルへjoin
#
################################################################################
echo "=========== Joining "$NODE" to channel "$CH" ==========="
docker-compose run --rm \
    $NODE peer channel join -b $CONFIG_BLOCK
# platformのAnchorPeer更新
docker-compose run --rm \
    $NODE /docker-bin/configtxgen -profile $CH -outputAnchorPeersUpdate $FABRIC_CFG_PATH/anchorUpdate.tx -channelID $CH -asOrg $ORG
# channel更新
docker-compose run --rm \
    $NODE peer channel update -c $CH -o $ORDERER:$ORDERER_PORT -f $FABRIC_CFG_PATH/anchorUpdate.tx





