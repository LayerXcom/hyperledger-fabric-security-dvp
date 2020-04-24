#!/bin/bash

# usage:
# MSPID=org3 TARGET_CHANNEL=all-ch FABRIC_TOOLS_BIN=/docker-bin ORDERER_HOST=orderer:7050 ./create_tx.sh channel
# MSPID=org3 TARGET_CHANNEL=all-ch FABRIC_TOOLS_BIN=/docker-bin ORDERER_HOST=orderer:7050 ./create_tx.sh consortium

set -eu

export FABRIC_CFG_PATH=$FABRIC_CFG_PATH

COMMAND=$1

ADD_ORG_TO_CHANNEL_JSON=$(cat << EOS
{
  "channel_group": {
    "groups": {
      "Application": {
        "groups": {"$MSPID": .[1]}
      }
    }
  }
}
EOS
)
ADD_ORG_TO_CONSORTIUM_JSON=$(cat << EOS
{
  "channel_group": {
    "groups": {
      "Consortiums": {
        "groups": {
          "Matilda": {
            "groups": {"$MSPID": .[1]}
          }
        }
      }
    }
  }
}
EOS
)

# prepare locally JSON files of both of current config and new adding org
# configPathによりFABRIC_CFG_PATHが変わってしまい、
# /etc/hyperledger/fabric/$MSPID/mspdir/$MSPID/mspにルート証明書を探しに行くため、一時的な回避策として
# /etc/hyperledger/fabric/mspdir/$MSPID/msp/cacertsを/etc/hyperledger/fabric/$MSPID/mspdir/$MSPID/mspにコピーする
mkdir -p /etc/hyperledger/fabric/$MSPID/mspdir/$MSPID/msp
cp -r /etc/hyperledger/fabric/mspdir/$MSPID/msp/cacerts /etc/hyperledger/fabric/$MSPID/mspdir/$MSPID/msp

case $COMMAND in
    "channel" )
        cp -r /etc/hyperledger/fabric/mspdir/$MSPID/msp/signcerts /etc/hyperledger/fabric/$MSPID/mspdir/$MSPID/msp
        cp -r /etc/hyperledger/fabric/mspdir/$MSPID/msp/keystore /etc/hyperledger/fabric/$MSPID/mspdir/$MSPID/msp
        cp -r /etc/hyperledger/fabric/mspdir/$MSPID/msp/admincerts /etc/hyperledger/fabric/$MSPID/mspdir/$MSPID/msp
        JSON=$ADD_ORG_TO_CHANNEL_JSON
        WORKING_DIR=$FABRIC_CFG_PATH/edit_channel_config/add_${MSPID}_to_${TARGET_CHANNEL} ;;
    "consortium" )
        JSON=$ADD_ORG_TO_CONSORTIUM_JSON
        WORKING_DIR=$FABRIC_CFG_PATH/edit_channel_config/add_${MSPID}_to_consortium ;;
    * ) echo "ERROR: you need to specify correct sub-command" && exit 1
esac

mkdir -p $WORKING_DIR

if [ ! -e $FABRIC_CFG_PATH/$MSPID/configtx.yaml ]; then
  echo "ERROR: configtx.yaml isn't exists under FABRIC_CFG_PATH" && exit 1
fi

# export CORE_PEER_LOCALMSPID=orderer
# export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/mspdir/orderer/msp
$FABRIC_TOOLS_BIN/configtxgen -printOrg $MSPID > $WORKING_DIR/1_${MSPID}.json -configPath $FABRIC_CFG_PATH/$MSPID

$FABRIC_TOOLS_BIN/peer channel fetch config $WORKING_DIR/2_config_block.pb -o $ORDERER_HOST -c $TARGET_CHANNEL
$FABRIC_TOOLS_BIN/configtxlator proto_decode --input $WORKING_DIR/2_config_block.pb --type common.Block | \
  $FABRIC_TOOLS_BIN/jq .data.data[0].payload.data.config > $WORKING_DIR/3_config.json

$FABRIC_TOOLS_BIN/jq -s ".[0] * $JSON" $WORKING_DIR/3_config.json $WORKING_DIR/1_${MSPID}.json > $WORKING_DIR/4_modified_config.json

# convert those JSON files into protocol buffers and then compute diff between the two using configtxlator
$FABRIC_TOOLS_BIN/configtxlator proto_encode \
  --type common.Config \
  --input $WORKING_DIR/3_config.json \
  --output $WORKING_DIR/5_config.pb
$FABRIC_TOOLS_BIN/configtxlator proto_encode \
  --type common.Config \
  --input $WORKING_DIR/4_modified_config.json \
  --output $WORKING_DIR/6_modified_config.pb
$FABRIC_TOOLS_BIN/configtxlator compute_update \
  --channel_id $TARGET_CHANNEL \
  --original $WORKING_DIR/5_config.pb \
  --updated $WORKING_DIR/6_modified_config.pb \
  --output $WORKING_DIR/7_${MSPID}_update.pb

# convert the pb file of diff into a transaction and send it
$FABRIC_TOOLS_BIN/configtxlator proto_decode --input $WORKING_DIR/7_${MSPID}_update.pb --type common.ConfigUpdate | \
  $FABRIC_TOOLS_BIN/jq . > $WORKING_DIR/8_${MSPID}_update.json

TX_ENVELOPE_JSON=$(cat << EOS
{
  "payload": {
    "header": {
      "channel_header": {
        "channel_id": "$TARGET_CHANNEL",
        "type": 2
      }
    },
    "data": {
      "config_update": $(cat $WORKING_DIR/8_${MSPID}_update.json)
    }
  }
}
EOS
)
echo $TX_ENVELOPE_JSON | $FABRIC_TOOLS_BIN/jq . > $WORKING_DIR/9_${MSPID}_update_in_envelope.json
$FABRIC_TOOLS_BIN/configtxlator proto_encode \
  --type common.Envelope \
  --input $WORKING_DIR/9_${MSPID}_update_in_envelope.json \
  --output $WORKING_DIR/${MSPID}_update_in_envelope.pb

rm -rf /etc/hyperledger/fabric/$MSPID/mspdir/$MSPID/msp/cacerts