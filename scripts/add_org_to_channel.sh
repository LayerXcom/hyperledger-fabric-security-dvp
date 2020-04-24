# !/bin/bash

echo
echo "=========== Add "$1" to "$2" channel ==========="

set -eu

. ./.env

ORG=$1
CH=$2
NODE=$3
OPERATION_PEER=$4
ORDERER_HOST=$5
TARGET_PEER=${ORG}-peer1
TARGET_PEER_PORT=$(eval echo '$'$(tr '[a-z]' '[A-Z]' <<<$ORG)_PEER_PORT)
################################################################################
#
#   チャネルに組織追加
#
################################################################################
mkdir -p ./nodes/$OPERATION_PEER/mspdir/$ORG/msp
cp -r ./nodes/$NODE/mspdir/$ORG/msp/cacerts ./nodes/$OPERATION_PEER/mspdir/$ORG/msp
# platform-peer1で対象のpeer(例えばminatobank-peer1)の代わりにanchor peer updateを実施するが、
# 処理を実行する際に対象のpeerの鍵が求められる
# joinするためのchannel update時はcaのみ必要だったが、なぜ全ての鍵が求められるのかについて原因調査が必要
# 一時的な回避策として対象peerの全鍵をplatform-peer1にコピー
cp -r ./nodes/$NODE/mspdir/$ORG/msp/admincerts ./nodes/$OPERATION_PEER/mspdir/$ORG/msp
cp -r ./nodes/$NODE/mspdir/$ORG/msp/signcerts ./nodes/$OPERATION_PEER/mspdir/$ORG/msp
cp -r ./nodes/$NODE/mspdir/$ORG/msp/keystore ./nodes/$OPERATION_PEER/mspdir/$ORG/msp

# platform-peer1が新しい組織をチャネルに追加
docker-compose run --rm \
    $OPERATION_PEER bash /scripts/update_channel.sh $CH $ORG

# join
docker-compose run --rm \
    $NODE bash /scripts/join_channel.sh $ORDERER_HOST $CH

# update anchor peer
docker-compose run --rm \
    $OPERATION_PEER bash /scripts/update_anchor_peer.sh $CH $ORG $TARGET_PEER $TARGET_PEER_PORT $ORDERER_HOST