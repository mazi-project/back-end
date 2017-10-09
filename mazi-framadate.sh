#!/bin/bash
#set -x
usage() { 
   echo "Usage: sudo sh mazi-stat.sh  [options]" 
   echo " " 
   echo "[options]"
   echo "--store           [enable] or [disable ]" 
   echo "-d,--domain       Set a remote server domain.( Default is localhost )" 1>&2; exit 1;
   
}

data_fun() {
   polls=$(echo "SELECT COUNT(*) FROM fd_poll WHERE active = '1';" | mysql -u$username -p$password framadate)
   polls=$(echo $polls | awk '{print $NF}')   

   votes=$(echo "SELECT COUNT(*) FROM fd_vote;" | mysql -u$username -p$password framadate)
   votes=$(echo $votes | awk '{print $NF}') 

   comments=$(echo "SELECT COUNT(*) FROM fd_comment;" | mysql -u$username -p$password framadate)
   comments=$(echo $comments | awk '{print $NF}')

   TIME=$(date  "+%H%M%S%d%m%y")
   data='{"deployment":'$(jq ".deployment" $conf)',
          "device_id":'$id',
          "date":'$TIME',
          "polls":"'$polls'",
          "comments":"'$comments'",
          "votes":"'$votes'"}'
   echo $data
}
##### Initialization ######
conf="/etc/mazi/mazi.conf"
interval="10"
domain="localhost"
 #Database
username=$(jq -r ".username" /etc/mazi/sql.json)
password=$(jq -r ".password" /etc/mazi/sql.json)
while [ $# -gt 0 ]
do
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
 shift
done

if [ $store ];then
  id=$(curl -s -X GET -d @$conf http://$domain:4567/device/id)
  [ ! $id ] && id=$(curl -s -X POST -d @$conf http://$domain:4567/deployment/register)
  curl -s -X POST --data '{"deployment":'$(jq ".deployment" $conf)'}' http://$domain:4567/create/framadate

  if [ $store = "enable" ];then
     while [ true ]; do
       target_time=$(( $(date +%s)  + $interval ))
       data_fun
       curl -s -X POST --data "$data" http://$domain:4567/update/framadate
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

#set +x
