# !/bin/bash

set -eu

. ./.env

ORG=$PLATFORM_MSPID
CA=$PLATFORM_CA
CA_PORT=$PLATFORM_CA_PORT
CA_HOST=$CA:$CA_PORT
NODE=$PLATFORM_PEER
PEER_ADMIN_ID=${PLATFORM_PEER}-admin
ENROLL_SECRET=password
IDENTITY=layerx
IDENTITY_PASSWORD=password
ORDERER_HOST=$ORDERER:$ORDERER_PORT
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
#   Identity新規登録(他のIdentityを新規発行できる権限を持つIdentity)
#
################################################################################
# layerx identity登録
docker-compose run --rm \
    $NODE bash /scripts/add_identity.sh $ORG $IDENTITY $IDENTITY_PASSWORD $CA_HOST