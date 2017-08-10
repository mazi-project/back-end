#!/bin/bash


#This script displays the total online users in the local network 
#
# Usage: sudo sh mazi-stat.sh  [options]
# 
# [options]
# -u,--users     Display online users 
#

#set -x

#### Functions ####
usage() { echo "Usage: sudo sh mazi-stat.sh  [options]" 
          echo " " 
          echo "[options]"
          echo "-t,--temp         Displays the CPU core temperature" 
          echo "-u,--users        Displays the total online users"
          echo "-c,--cpu          Displays the CPU usage" 
          echo "-r,--ram          Displays the RAM usage"
          echo "-s,--storage      Displays the percentage of used storage"
          echo "-n,--network      Displays the Download/Upload speed" 
          echo "--store           [enable] or [disable ]" 1>&2; exit 1; 
}

users_fun() {
    sudo touch $log/users.log
    sudo chmod 777 $log/users.log 
    if [ "$ROUTER" ];then
      sudo arp-scan --interface=eth0 10.0.2.0/24 --arpspa 10.0.2.1 --retry=3 -g  > $log/users.log
      users=$(cat $log/users.log | grep 'responded' | awk '{print $12}') 
      users=$(( users - 1))
    else
      sudo arp-scan --interface=wlan0 10.0.0.0/24 --arpspa 10.0.0.1 --retry=3 -g  > $log/users.log
      users=$(cat $log/users.log | grep 'responded' | awk '{print $12}')
    fi
    echo $users
}

temp_fun(){
   temp=$(vcgencmd measure_temp | grep -o '[0-9]*\.*[0-9]*')
   echo $temp
}

cpu_fun(){
   cpu=$(top -d 1 -b -n2 | grep "Cpu(s)"|tail -n 1 | awk '{print ($2 + $4)"%"}' | grep -o '[0-9]*\.*[0-9]*')
   echo $cpu
}

ram_fun(){
   ram=$(free -k | grep Mem | awk '{printf"%3.1f%%\n",($3/$2*100)}'| grep -o '[0-9]*\.*[0-9]*')
   echo $ram
}

storage_fun(){
   storage=$(df -h | grep root | awk '{print $5}'| grep -o '[0-9]*\.*[0-9]*')
   echo $storage
}
network_fun(){
 result="$(speedtest-cli | grep -e Upload: -e Download:)"
 download=$(echo $result | awk '{print $2, $3}')  
 upload=$(echo $result | awk '{print $5, $6}')
}



###### Initialization ######
path="/root/back-end"
log="/etc/mazi"
features="/etc/mazi/features.json"
interval="10"

rasp_users="null"
rasp_temp="null"
rasp_cpu="null"
rasp_ram="null"
rasp_storage="null"
upload="null"
download="null"

if [ "$(sh $path/current.sh -w)" = "device OpenWrt router" ];then
   ROUTER="TRUE"
fi

######  Parse command line arguments   ######
while [ $# -gt 0 ]
do
  key="$1"
 
  case $key in
      -u|--users)
      users="TRUE" 
      rasp_users=$(users_fun)
      echo "wifi users" $rasp_users
      ;;
      -t|--temp)
      temp="TRUE"
      rasp_temp=$(temp_fun)
      echo "temp="$rasp_temp"'C"
      ;; 
      -c|--cpu)
      cpu="TRUE"
      rasp_cpu=$(cpu_fun)
      echo "$rasp_cpu%"
      ;;
      -r|-ram)
      ram="TRUE"
      rasp_ram=$(ram_fun)
      echo "$rasp_ram%"
      ;;
      -s|-storage)
      storage="TRUE"
      rasp_storage=$(storage_fun)
      echo "$rasp_storage%"
      ;;
      -n|--network)
      network="TRUE"
      interval="60"
      network_fun
      echo "Download" $download
      echo "Upload" $upload
      ;;
      --store)
      store="$2"
      shift
      ;;
      *)
      # unknown option
      usage   
      ;;
  esac
  shift #past argument or value
done


if [ $store ];then
 # take id  
 id=$(curl -s -X GET -d @$features http://10.0.0.1:4567/device/id)
 [ ! $id ] && id=$(curl -s -X POST -d @$features http://10.0.0.1:4567/deployment/register) 
 if [ $store = "enable" ];then
  while [ true ]; do

   ## edw tha kanw to call
   TIME=$(date  "+%H%M%S%d%m%y") 
   data='{"deployment":'$(jq ".deployment" $features)',
          "device_id":'$id',
          "date":'$TIME',
          "users":'$rasp_users',
          "temp":'$rasp_temp',
          "cpu":'$rasp_cpu',
          "ram":'$rasp_ram',
          "storage":'$rasp_storage',
          "network":{"upload":"'$upload'","download":"'$download'"} }'
  
    if [ ! $create ];then
      curl -s -X POST --data "$data" http://10.0.0.1:4567/create/statistics 
      create="ok"
    else
      curl -s -X POST --data "$data" http://10.0.0.1:4567/update/statistics
    fi

    target_time=$(( $(date +%s)  + $interval ))
    [ $users ] && rasp_users=$(users_fun)
    [ $temp ] && rasp_temp=$(temp_fun)
    [ $cpu ] && rasp_cpu=$(cpu_fun) 
    [ $ram ] && rasp_ram=$(ram_fun)
    [ $storage ] && rasp_storeage=$(storage_fun)
    [ $network ] && network_fun

    current_time=$(date +%s)
    sleep_seconds=$(( $target_time - $current_time ))
    [ $sleep_seconds -gt 0 ] && sleep $sleep_seconds 
  done
 elif [ $store = "disable" ];then
   Pid=$(ps aux | grep -F "store enable" | grep -v 'grep' | awk '{print $2}' )
   [ $Pid ] && kill $Pid && echo " disable"
 else
   echo "WRONG ARGUMENT"
   usage
 fi
fi

