# !/bin/bash

echo
echo "=========== Add "$1" to consortium ==========="

set -eu

. ./.env

ORG=$1
NODE=$2
ORDERER=$3
################################################################################
#
#   コンソーシアムに組織追加
#
################################################################################
mkdir -p ./nodes/$ORDERER/mspdir/$ORG/msp
cp -r ./nodes/$NODE/mspdir/$ORG/msp/cacerts ./nodes/$ORDERER/mspdir/$ORG/msp

# OrdererにもPeerの設定ファイルを配置(これがないとpeerコマンド時に怒られる)
cp ./configs/common/$CONFIG_FILE_NAME ./nodes/$ORDERER/$CONFIG_FILE_NAME

# Ordererが新しい組織をコンソーシアムに追加
docker-compose run --rm \
    $ORDERER bash /scripts/update_consortium.sh $ORG