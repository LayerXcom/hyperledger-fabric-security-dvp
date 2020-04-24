# !/bin/bash

echo
echo "=========== Add Minato Bank =========== "

set -eu

. ./.env

ORG=$MINATOBANK_MSPID
CA=$MINATOBANK_CA
CA_PORT=$MINATOBANK_CA_PORT
CA_HOST=$CA:$CA_PORT
NODE=$MINATOBANK_PEER
PEER_ADMIN_ID=minatobank-peer1-admin
ENROLL_SECRET=password
OPERATION_PEER=$PLATFORM_PEER
################################################################################
#
#   CAの設定と起動
#
################################################################################
. ./scripts/boost_ca.sh $CA $CA_PORT $PEER_ADMIN_ID $ENROLL_SECRET

################################################################################
#
#   Peerの設定と起動
#
################################################################################
. ./scripts/boost_peer.sh $ORG $CA_HOST $NODE $PEER_ADMIN_ID $ENROLL_SECRET

################################################################################
#
#   コンソーシアムに組織追加
#
################################################################################
. ./scripts/add_org_to_consortium.sh $ORG $NODE $ORDERER

################################################################################
#
#   チャネルに組織追加
#
################################################################################
. ./scripts/add_org_to_channel.sh $ORG $CH $NODE $OPERATION_PEER $ORDERER:$ORDERER_PORT