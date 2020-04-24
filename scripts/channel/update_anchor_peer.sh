#!/bin/bash

set -eu

CH=$1
MSPID=$2
TARGET_PEER=$3
TARGET_PEER_PORT=$4
ORDERER_HOST=$5
FABRIC_TOOLS_BIN=/docker-bin
WORKING_DIR=/etc/hyperledger/fabric/${MSPID}_update_anchor_peer
mkdir $WORKING_DIR

export CORE_PEER_LOCALMSPID=${MSPID}
export CORE_PEER_MSPCONFIGPATH=mspdir/${MSPID}/msp

ANCHOR_PEER_JSON=$(cat << EOS
{
    "AnchorPeers":{
        "mod_policy": "Admins",
        "value":{
            "anchor_peers": [{"host": "${TARGET_PEER}","port": ${TARGET_PEER_PORT}}]
        },
        "version": "0"
    }
}
EOS
)

peer channel fetch \
    config $WORKING_DIR/config_block.pb -o $ORDERER_HOST -c ${CH}
$FABRIC_TOOLS_BIN/configtxlator \
    proto_decode \
    --input $WORKING_DIR/config_block.pb \
    --type common.Block | $FABRIC_TOOLS_BIN/jq .data.data[0].payload.data.config > $WORKING_DIR/config.json
$FABRIC_TOOLS_BIN/jq ".channel_group.groups.Application.groups.${MSPID}.values += $ANCHOR_PEER_JSON" $WORKING_DIR/config.json > \
    $WORKING_DIR/modified_anchor_config.json
$FABRIC_TOOLS_BIN/configtxlator \
    proto_encode \
    --input $WORKING_DIR/config.json \
    --type common.Config --output $WORKING_DIR/config.pb
$FABRIC_TOOLS_BIN/configtxlator \
    proto_encode \
    --input $WORKING_DIR/modified_anchor_config.json \
    --type common.Config \
    --output $WORKING_DIR/modified_anchor_config.pb
$FABRIC_TOOLS_BIN/configtxlator \
    compute_update \
    --channel_id ${CH} \
    --original $WORKING_DIR/config.pb \
    --updated $WORKING_DIR/modified_anchor_config.pb \
    --output $WORKING_DIR/anchor_update.pb
$FABRIC_TOOLS_BIN/configtxlator \
    proto_decode \
    --input $WORKING_DIR/anchor_update.pb \
    --type common.ConfigUpdate | $FABRIC_TOOLS_BIN/jq . > $WORKING_DIR/anchor_update.json
PAYLOAD_JSON=$(cat << EOS
{
    "payload":{
        "header":{
            "channel_header":{
                "channel_id":"${CH}",
                "type":2
            }
        },
        "data":{
            "config_update":$(cat $WORKING_DIR/anchor_update.json)
        }
    }
}
EOS
)
echo $PAYLOAD_JSON | $FABRIC_TOOLS_BIN/jq . > $WORKING_DIR/anchor_update_in_envelope.json
$FABRIC_TOOLS_BIN/configtxlator \
    proto_encode \
    --input $WORKING_DIR/anchor_update_in_envelope.json \
    --type common.Envelope \
    --output $WORKING_DIR/anchor_update_in_envelope.pb
peer channel \
    signconfigtx \
    -f $WORKING_DIR/anchor_update_in_envelope.pb

echo
echo "=========== Updating anchor peer ==========="
# channel update
peer channel \
    update -f $WORKING_DIR/anchor_update_in_envelope.pb -c ${CH} -o $ORDERER_HOST