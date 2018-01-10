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
echo "$NDJS_LOG_DATE cheking newest node.js version"
for line in $(cat $NDJS_LIST)
do
    ndjs_rep=$(echo $line | awk -F '=' '{print$1}')
    ndjs_ver=$(echo $line | awk -F '=' '{print$2}')
    newset_ver=$(curl --silent --get --retry 5 --retry-max-time 15 --data-urlencode "range=${ndjs_rep}" "$TAKE_URL" | awk '{print $1}')
    if [ $newset_ver != $ndjs_ver ];then
        echo "$NDJS_LOG_DATE replacing older node.js package"
        wget $DOWNLOAD_URL/node-v$newset_ver-linux-x64.tar.gz -O /tmp/node-v$newset_ver-linux-x64.tar.gz
            if [  $? -eq 0  ];then
                echo "$NDJS_LOG_DATE : update to node-v$newset_ver-linux-x64.tar.gz success" >> /var/log/ndjs_info.log
            else
                echo "$NDJS_LOG_DATE : update to node-v$newset_ver-linux-x64.tar.gz fail" >> /var/log/ndjs_info.err
            fi
        sed -i "s/$ndjs_ver/$newset_ver/" $NDJS_LIST
        /root/bin/ossutil64 cp -f /tmp/node-v$newset_ver-linux-x64.tar.gz $OSS_URL/node/v${newset_ver}/node-v$newset_ver-linux-x64.tar.gz
        echo "$NDJS_LOG_DATE copy node-v$newset_ver-linux-x64.tar.gz to oss complete"
        rm /tmp/node-v$newset_ver-linux-x64.tar.gz
    else
        echo "$NDJS_LOG_DATE $ndjs_ver is newest version in $ndjs_rep"
    fi
done
    /root/bin/ossutil64 cp -f $NDJS_LIST ${OSS_URL}/node/ndjs-list
    rm $NDJS_LIST
}

function msg_tasks() {
    if [ -f /var/log/ndjs_info.log ];then
        dd_uptate_info
        rm /var/log/ndjs_info.log
    elif [ -f /var/log/ndjs_info.err ];then
        dd_download_err
        rm /var/log/ndjs_info.err
    else
        dd_nothing_info
    fi
}

function dd_nothing_info() {
    log_info=$(cat /var/log/ndjs_info.log)
    curl 'https://oapi.dingtalk.com/robot/send?access_token=6786cba9d28faf7241b3c5de63351c49f8e1286564c49a24058f0d5cb3bc4045' \
    -H 'Content-Type: application/json' \
    -d '{
        "msgtype": "text", 
            "text": {
                "content": "'"$NDJS_LOG_DATE : node.js-version均为最新版，未更新"'"
            },
            "at": {
            "atMobiles": ["17614720053"],
            }
        }'
}

#钉钉更新提示
function dd_uptate_info() {
    log_info=$(cat /var/log/ndjs_info.log)
    curl 'https://oapi.dingtalk.com/robot/send?access_token=6786cba9d28faf7241b3c5de63351c49f8e1286564c49a24058f0d5cb3bc4045' \
    -H 'Content-Type: application/json' \
    -d '{
        "msgtype": "text", 
            "text": {
                "content": "'"$log_info"'"
            },
            "at": {
            "atMobiles": ["17614720053"],
            }
        }'
}

#钉钉提示未下载成功
function dd_download_err() {
    err_info=$(cat /var/log/ndjs_info.err)
    curl 'https://oapi.dingtalk.com/robot/send?access_token=6786cba9d28faf7241b3c5de63351c49f8e1286564c49a24058f0d5cb3bc4045' \
    -H 'Content-Type: application/json' \
    -d '{
        "msgtype": "text", 
            "text": {
                "content": "'"$err_info"'"
            },
            "at": {
            "atMobiles": ["17614720053"],
            }
        }'
}

prepare
check 
msg_tasks