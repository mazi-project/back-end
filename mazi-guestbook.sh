#!/bin/bash

usage() { 
   echo "Usage: sudo sh mazi-stat.sh  [options]" 
   echo " " 
   echo "[options]"
   echo "--store           [enable] or [disable ]" 1>&2; exit 1;
}

data_fun() {
   submissions=$(mongo letterbox  --eval "printjson(db.submissions.find().count())")
   submissions=$(echo $submissions | awk '{print $NF}')
 
   images=$(mongo letterbox  --eval "printjson(db.submissions.find({files:[]}).count())")
   images=$(( $submissions - $(echo $images | awk '{print $NF}') )) 

   comments=$(mongo letterbox  --eval "printjson(db.comments.find().count())")
   comments=$(echo $comments | awk '{print $NF}')
 
   datasize=$(mongo letterbox --eval "printjson(db.stats().dataSize)")
   datasize=$(echo $datasize | awk '{print $NF}')
  
   TIME=$(date  "+%H%M%S%d%m%y")
   data='{"deployment":'$(jq ".deployment" $features)',
          "device_id":'$id',
          "date":'$TIME',
          "submissions":'$submissions',
          "comments":'$comments',
          "images":'$images',
          "datasize":'$datasize'}'
  echo $data
}
##### Initialization ######
features="/etc/mazi/features.json"
interval="10"

key="$1"
case $key in
      --store)
      store="$2"
      shift
      ;;
      *)
      # unknown option
      usage   
      ;;
esac

if [ $store ];then
  id=$(curl -s -X GET -d @$features http://10.0.0.1:4567/device/id)
  [ ! $id ] && id=$(curl -s -X POST -d @$features http://10.0.0.1:4567/deployment/register)
  curl -s -X POST --data '{"deployment":'$(jq ".deployment" $features)'}' http://10.0.0.1:4567/create/guestbook 

  if [ $store = "enable" ];then
     while [ true ]; do
       target_time=$(( $(date +%s)  + $interval ))
       data_fun
       curl -s -X POST --data "$data" http://10.0.0.1:4567/update/guestbook
       current_time=$(date +%s)
       sleep_time=$(( $target_time - $current_time ))
       [ $sleep_time -gt 0 ] && sleep $sleep_time
     done
  elif [ $store = "disable" ];then
   Pid=$(ps aux | grep -F "store enable" | grep -v 'grep' | awk '{print $2}' )
   [ $Pid ] && kill $Pid && echo " disable"
  else
   echo "WRONG ARGUMENT"
   usage

  fi
fi

