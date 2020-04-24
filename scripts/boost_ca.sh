# !/bin/bash

echo
echo "=========== Boost "$1" ==========="

set -eu

. ./.env

CA=$1 #platform-ca
CA_PORT=$2 #7054
################################################################################
#
#   CAの設定と起動
#
################################################################################
docker-compose up -d $CA

# CAの管理者Identityを作成（registerはCA起動時のコマンドで実行済み）
docker-compose run --rm \
    $CA fabric-ca-client enroll -u http://$ADMIN_ID:$ADMIN_PASSWORD@$CA:$CA_PORT