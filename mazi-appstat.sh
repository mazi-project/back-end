#!/bin/bash
#set -x
usage() { 
   echo "Usage: sudo sh mazi-appstat.sh [Application name] [options]" 
   echo " " 
   echo "[Application name]"
   echo "-n,--name         Set the name of the application"
   echo ""
   echo "[options]"
   echo "--store           [enable] , [disable] or [flush]"
   echo "--status          Displays the status of store process" 
   echo "-d,--domain       Set a remote server domain.( Default is localhost )" 1>&2; exit 1;
}

data_etherpad() {
   users=$(mysql -u$username -p$password etherpad -e 'select store.value from store' |grep -o '"padIDs":{".*":.*}}' | wc -l)

   pads=$(mysql -u$username -p$password etherpad -e 'select store.key from store' |grep -Eo '^pad:[^:]+' |sed -e 's/pad://' |sort |uniq -c |sort -rn |awk '(count+=1) {if ($1!="2") { print count}}' |tail -1)

   datasize=$(echo "SELECT ROUND(SUM(data_length + index_length), 2)  as Size_in_B FROM information_schema.TABLES 
          WHERE table_schema = 'etherpad';" | mysql -u$username -p$password)
   datasize=$(echo $datasize | awk '{print $NF}')
  
   TIME=$(date  "+%H%M%S%d%m%y")
   data='{"deployment":'$(jq ".deployment" $conf)',
          "device_id":"'$id'",
          "date":'$TIME',
          "pads":"'$pads'",
          "users":"'$users'",
          "datasize":"'$datasize'"}'
  echo $data
}

data_framadate() {
   polls=$(echo "SELECT COUNT(*) FROM fd_poll WHERE active = '1';" | mysql -u$username -p$password framadate)
   polls=$(echo $polls | awk '{print $NF}')   

   votes=$(echo "SELECT COUNT(*) FROM fd_vote;" | mysql -u$username -p$password framadate)
   votes=$(echo $votes | awk '{print $NF}') 

   comments=$(echo "SELECT COUNT(*) FROM fd_comment;" | mysql -u$username -p$password framadate)
   comments=$(echo $comments | awk '{print $NF}')

   TIME=$(date  "+%H%M%S%d%m%y")
   data='{"deployment":'$(jq ".deployment" $conf)',
          "device_id":"'$id'",
          "date":'$TIME',
          "polls":"'$polls'",
          "comments":"'$comments'",
          "votes":"'$votes'"}'
   echo $data
}

data_guestbook() {
   submissions=$(mongo letterbox  --eval "printjson(db.submissions.find().count())")
   submissions=$(echo $submissions | awk '{print $NF}')

   images=$(mongo letterbox  --eval "printjson(db.submissions.find({files:[]}).count())")
   images=$(( $submissions - $(echo $images | awk '{print $NF}') )) 

   comments=$(mongo letterbox  --eval "printjson(db.comments.find().count())")
   comments=$(echo $comments | awk '{print $NF}')

   datasize=$(mongo letterbox --eval "printjson(db.stats().dataSize)")
   datasize=$(echo $datasize | awk '{print $NF}')

   TIME=$(date  "+%H%M%S%d%m%y")
   data='{"deployment":'$(jq ".deployment" $conf)',
          "device_id":"'$id'",
          "date":'$TIME',
          "submissions":"'$submissions'",
          "comments":"'$comments'",
          "images":"'$images'",
          "datasize":"'$datasize'"}'
  echo $data
}

store(){
   NAME=$1
   while [ true ]; do
     target_time=$(( $(date +%s)  + $interval ))
     data_$NAME
     response=$(curl -s -w %{http_code} -X POST --data "$data" http://$domain:4567/update/$NAME)
     http_code=$(echo $response | tail -c 4)
     body=$(echo $response| rev | cut -c 4- | rev )
     sed -i "/$NAME/c\\$NAME: $body http_code: $http_code" /etc/mazi/rest.log
     current_time=$(date +%s)
     sleep_time=$(( $target_time - $current_time ))
     [ $sleep_time -gt 0 ] && sleep $sleep_time
   done
}

disable(){

   Pid=$(ps aux | grep "mazi-appstat" | grep -v 'grep' | awk '{print $2}')
   for i in $Pid; do
     kill $i 
     echo "disable"
   done
}

status_call() {
  error=""
  call_st=""
  if [ -f /etc/mazi/rest.log ];then
    response=$(tac /etc/mazi/rest.log| grep "$1" | awk -v FS="($1:|http_code:)" '{print $2}')
    http_code=$(tac /etc/mazi/rest.log| grep "$1" | head -1 | awk '{print $NF}')
  fi
  [ "$http_code" = "200" -a "$response" = " OK " ] && call_st="OK" && error=""
  [ "$http_code" = "000" ] && call_st="ERROR:" && error="Connection refused"
  [ "$http_code" = "200" -a "$response" != " OK " ] && call_st="ERROR:" && error="$response"
  [ "$http_code" = "500" ] && call_st="ERROR:" && error="The server encountered an unexpected condition which prevented it from fulfilling the request"

}


##### Initialization ######
conf="/etc/mazi/mazi.conf"
interval="60"
domain="localhost"
 #Database
username=$(jq -r ".username" /etc/mazi/sql.conf)
password=$(jq -r ".password" /etc/mazi/sql.conf)

while [ $# -gt 0 ]
do

  key="$1"
  case $key in
      -n|--name)
      apps="$2"
      shift
      ;;
      --store)
      store="$2"
      shift
      ;;
      -s|--status)
      status="TRUE"
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
  shift     #past argument or value
done


if [ $status ];then
  status_call guestbook
  [ "$(ps aux | grep "mazi-appstat"| grep "store enable" | grep "guestbook" | grep -v 'grep' | awk '{print $2}')" ] && echo "guestbook active $call_st $error" || echo "guestbook inactive $call_st $error"
  status_call etherpad 
  [ "$(ps aux | grep "mazi-appstat"| grep "store enable" | grep "etherpad" | grep -v 'grep' | awk '{print $2}')" ] && echo "etherpad active $call_st $error" || echo "etherpad inactive $call_st $error"
  status_call framadate
  [ "$(ps aux | grep "mazi-appstat"| grep "store enable" | grep "framadate" | grep -v 'grep' | awk '{print $2}')" ] && echo "framadate active $call_st $error" || echo "framadate inactive $call_st $error" 


fi

if [ $store ];then
  id=$(curl -s -X GET -d @$conf http://$domain:4567/device/id)
  [ ! $id ] && id=$(curl -s -X POST -d @$conf http://$domain:4567/monitoring/register)


  if [ $store = "enable" ];then
   
    for i in $apps; do 
       [ ! -f /etc/mazi/rest.log -o ! "$(grep -R "$i:" /etc/mazi/rest.log)" ] && echo "$i:" >> /etc/mazi/rest.log
       curl -s -X POST http://$domain:4567/create/$i
    done
    for i in $apps; do
       store $i &  
    done
  elif [ $store = "disable" ];then
    disable
  elif [ $store = "flush" ];then
    for i in $apps; do
       curl -s -X POST --data '{"device_id":'$id'}' http://$domain:4567/flush/$i 
    done  
  else
   echo "WRONG ARGUMENT"
   usage

  fi
fi




#set +x
