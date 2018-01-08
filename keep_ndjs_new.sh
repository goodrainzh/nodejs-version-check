#!/bin/bash 

NDJS_LIST=/tmp/ndjs-list.$$
OSS_URL="oss://lang-goodrain-me"
DOWNLOAD_URL="https://s3.amazonaws.com/heroku-nodejs-bins/node/release/linux-x64"
TAKE_URL="https://nodebin.herokai.com/v1/node/linux-x64/latest.txt"
NDJS_LOG_DATE=`date "+%Y-%m-%d %H:%M:%S"`

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
            if [  $? -eq 0  ]
            then
                dd_uptate_info
            else
                dd_download_err
            fi
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
dd__normal_info
}

#钉钉更新提示
function dd_uptate_info() {
    curl 'https://oapi.dingtalk.com/robot/send?access_token=6786cba9d28faf7241b3c5de63351c49f8e1286564c49a24058f0d5cb3bc4045' \
    -H 'Content-Type: application/json' \
    -d '{
        "msgtype": "text", 
            "text": {
                "content": "node.js均为最新版，无需更新"
            },
            "at": {
            "atMobiles": ["17614720053"],
            }
        }'
}

#钉钉提示正常
function dd__normal_info() {
    curl 'https://oapi.dingtalk.com/robot/send?access_token=6786cba9d28faf7241b3c5de63351c49f8e1286564c49a24058f0d5cb3bc4045' \
    -H 'Content-Type: application/json' \
    -d '{
        "msgtype": "text", 
            "text": {
                "content": "node.js均为最新版，未下载更新"
            },
            "at": {
            "atMobiles": ["17614720053"],
            }
        }'
}

#钉钉提示未下载成功
function dd_download_err() {
    curl 'https://oapi.dingtalk.com/robot/send?access_token=6786cba9d28faf7241b3c5de63351c49f8e1286564c49a24058f0d5cb3bc4045' \
    -H 'Content-Type: application/json' \
    -d '{
        "msgtype": "text", 
            "text": {
                "content": "node.js下载异常"
            },
            "at": {
            "atMobiles": ["17614720053"],
            }
        }'
}

prepare
check