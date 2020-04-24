#!/bin/bash

set -eu

ORDERER_HOST=$1
CH=$2
GENESIS_BLOCK=/etc/hyperledger/fabric/genesis.block

# チャネルのgenesis block取得
peer channel fetch oldest $GENESIS_BLOCK -c $CH -o $ORDERER_HOST

# join
echo
echo "=========== Joining "$CORE_PEER_ID" to channel "$CH" ==========="
peer channel join -b $GENESIS_BLOCK

# 確認
peer channel list