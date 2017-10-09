#!/bin/bash

usage() { 
   echo "Usage: sudo sh mazi-etherpad.sh  [options]" 
   echo " " 
   echo "[options]"
   echo "--store           [enable] or [disable ]" 
   echo "-d,--domain       Set a remote server domain.( Default is localhost )" 1>&2; exit 1;
}

data_fun() {
   users=$(mysql -u$username -p$password etherpad -e 'select store.value from store' |grep -o '"padIDs":{".*":.*}}' | wc -l)

   pads=$(mysql -u$username -p$password etherpad -e 'select store.key from store' |grep -Eo '^pad:[^:]+' |sed -e 's/pad://' |sort |uniq -c |sort -rn |awk '(count+=1) {if ($1!="2") { print count}}' |tail -1)

   datasize=$(echo "SELECT ROUND(SUM(data_length + index_length), 2)  as Size_in_B FROM information_schema.TABLES 
          WHERE table_schema = 'etherpad';" | mysql -u$username -p$password)
   datasize=$(echo $datasize | awk '{print $NF}')
  
   TIME=$(date  "+%H%M%S%d%m%y")
   data='{"deployment":'$(jq ".deployment" $conf)',
          "device_id":'$id',
          "date":'$TIME',
          "pads":"'$pads'",
          "users":"'$users'",
          "datasize":'$datasize'}'
  echo $data
}
##### Initialization ######
conf="/etc/mazi/mazi.conf"
interval="10"
domain="localhost"
 #Database
username=$(jq -r ".username" /etc/mazi/sql.json)
password=$(jq -r ".password" /etc/mazi/sql.json)

key="$1"
case $key in
      --store)
      store="$2"
      shift
      ;;
      -d|--domain)
      domain="$2"
      shift
      ;;
      *)
      # unknown option
      usage   
      ;;
esac


if [ $store ];then
  id=$(curl -s -X GET -d @$conf http://$domain:4567/device/id)
  [ ! $id ] && id=$(curl -s -X POST -d @$conf http://$domain:4567/deployment/register)
  curl -s -X POST --data '{"deployment":'$(jq ".deployment" $conf)'}' http://$domain:4567/create/etherpad

  if [ $store = "enable" ];then
     while [ true ]; do
       target_time=$(( $(date +%s)  + $interval ))
       data_fun
       curl -s -X POST --data "$data" http://$domain:4567/update/etherpad
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







