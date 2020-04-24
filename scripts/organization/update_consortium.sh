#!/bin/bash

set -eu

# jqインストール
. $(dirname $0)/install_jq.sh

export FABRIC_CFG_PATH=/etc/hyperledger/fabric

ORDERER_HOST=orderer:7050
FABRIC_TOOLS_BIN=/docker-bin
TARGET_ORG=$1
################################################################################
#
#   コンソーシアムに新しい組織を追加
#
################################################################################
MSPID=$TARGET_ORG \
TARGET_CHANNEL=testchainid \
FABRIC_TOOLS_BIN=$FABRIC_TOOLS_BIN \
ORDERER_HOST=$ORDERER_HOST \
. $(dirname $0)/create_tx.sh consortium

# コンソーシアム更新
$FABRIC_TOOLS_BIN/peer channel update -c testchainid -o $ORDERER_HOST -f $FABRIC_CFG_PATH/edit_channel_config/add_${TARGET_ORG}_to_consortium//${TARGET_ORG}_update_in_envelope.pb

# ログ確認用
WORKING_DIR=$FABRIC_CFG_PATH/edit_channel_config/add_${TARGET_ORG}_to_consortium
$FABRIC_TOOLS_BIN/peer channel fetch config $WORKING_DIR/config_block.pb -o $ORDERER_HOST -c testchainid
$FABRIC_TOOLS_BIN/configtxlator proto_decode --input $WORKING_DIR/config_block.pb --type common.Block | \
  $FABRIC_TOOLS_BIN/jq .data.data[0].payload.data.config > $WORKING_DIR/config_log.json