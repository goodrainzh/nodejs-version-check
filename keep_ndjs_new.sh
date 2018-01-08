#!/bin/bash 

NDJS_LIST=/tmp/ndjs-list.$$
OSS_URL="oss://lang-goodrain-me"
DOWNLOAD_URL="https://s3.amazonaws.com/heroku-nodejs-bins/node/release/linux-x64"
TAKE_URL="https://nodebin.herokai.com/v1/node/linux-x64/latest.txt"

function prepare() {
    /root/bin/ossutil64 cp -f $OSS_URL/node/ndjs-list $NDJS_LIST
}

function check() {
echo "cheking newest node.js version"
for line in $(cat $NDJS_LIST)
do
    ndjs_rep=$(echo $line | awk -F '=' '{print$1}')
    ndjs_ver=$(echo $line | awk -F '=' '{print$2}')
    newset_ver=$(curl --silent --get --retry 5 --retry-max-time 15 --data-urlencode "range=${ndjs_rep}" "$TAKE_URL" | awk '{print $1}')
    if [ $newset_ver != $ndjs_ver ];then
        echo "replacing older node.js package"
        wget $DOWNLOAD_URL/node-v$newset_ver-linux-x64.tar.gz -O /tmp/node-v$newset_ver-linux-x64.tar.gz
        sed "s/$ndjs_ver/$newset_ver/" $NDJS_LIST
        /root/bin/ossutil64 cp -f /tmp/node-v$newset_ver-linux-x64.tar.gz $OSS_URL/node/v${newset_ver}/node-v$newset_ver-linux-x64.tar.gz
        echo "copy node-v$newset_ver-linux-x64.tar.gz to oss complete"
        rm /tmp/node-v$newset_ver-linux-x64.tar.gz
    else
        echo "$ndjs_ver is newest version in $ndjs_rep"
    fi
done
/root/bin/ossutil64 cp -f $NDJS_LIST ${OSS_URL}/node/ndjs-list
rm $NDJS_LIST
}

prepare
check