#!/bin/bash

usage() { 
   echo "Usage: sudo sh mazi-stat.sh  [options]" 
   echo " " 
   echo "[options]"
   echo "--store           [enable] or [disable ]" 1>&2; exit 1;
}

data_fun() {
   polls=$(echo "SELECT COUNT(*) FROM fd_poll WHERE active = '1';" | mysql -uroot -pm@z1 framadate)
   polls=$(echo $polls | awk '{print $NF}')   

   votes=$(echo "SELECT COUNT(*) FROM fd_vote;" | mysql -uroot -pm@z1 framadate)
   votes=$(echo $votes | awk '{print $NF}') 

   comments=$(echo "SELECT COUNT(*) FROM fd_comment;" | mysql -uroot -pm@z1 framadate)
   comments=$(echo $comments | awk '{print $NF}')
   

   datasize=$(echo "SELECT ROUND(SUM(data_length + index_length), 2)  as Size_in_B FROM information_schema.TABLES 
          WHERE table_schema = 'framadate';" | mysql -uroot -pm@z1)
   datasize=$(echo $datasize | awk '{print $NF}')
     
   TIME=$(date  "+%H%M%S%d%m%y")
   data='{"deployment":'$(jq ".deployment" $features)',
          "device_id":'$id',
          "date":'$TIME',
          "polls":'$polls',
          "comments":'$comments',
          "votes":'$votes',
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
  curl -s -X POST --data '{"deployment":'$(jq ".deployment" $features)'}' http://10.0.0.1:4567/create/framadate

  if [ $store = "enable" ];then
     while [ true ]; do
       target_time=$(( $(date +%s)  + $interval ))
       data_fun
       curl -s -X POST --data "$data" http://10.0.0.1:4567/update/framadate
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

