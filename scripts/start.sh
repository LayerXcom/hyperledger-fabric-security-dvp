#!/bin/sh

set -eu

# docker-toolsコンテナから下記の４つのツールをローカルにコピーする。
#   peer
#   configtxgen
#   configtxlator
#   jq
# 必要に応じてコンテナに追加して使用する。が、jqが動作しなく、コンテナ内で別途installする必要ある
echo
echo "============================================= "
echo "=========== Build matilda network =========== "
echo "============================================= "
echo

if [ ! -e ./docker-bin/peer ]; then
    ./scripts/copy_fabric_tools.sh
fi

for SCRIPT in $(ls ./scripts/ | egrep -e "[1-99]+_.*\.sh" | sort)
do
    ./scripts/$SCRIPT
    RESULT=$?
    if [ $RESULT != 0 ]; then
        exit 1
    fi
done

echo
echo "=========================================================== "
echo "=========== All GOOD, start execution completed =========== "
echo "=========================================================== "
echo