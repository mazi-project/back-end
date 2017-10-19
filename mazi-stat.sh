#!/bin/bash

#This script displays the total online users in the local network 
#
# Usage: sudo sh mazi-stat.sh  [options]
# 
# [options]
# -u,--users     Display online users 
#

set -x

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
          echo "--store           [enable] or [disable ]"
          echo "-d,--domain       Set a remote server domain.( Default is localhost )" 1>&2; exit 1; 
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
}

temp_fun(){
   temp=$(vcgencmd measure_temp | grep -o '[0-9]*\.*[0-9]*')
}

cpu_fun(){
   cpu=$(top -d 1 -b -n2 | grep "Cpu(s)"|tail -n 1 | awk '{print ($2 + $4)"%"}' | grep -o '[0-9]*\.*[0-9]*')
}

ram_fun(){
   ram=$(free -k | grep Mem | awk '{printf"%3.1f%%\n",($3/$2*100)}'| grep -o '[0-9]*\.*[0-9]*')
}

storage_fun(){
   storage=$(df -h | grep root | awk '{print $5}'| grep -o '[0-9]*\.*[0-9]*')
}
network_fun(){
 result="$(speedtest-cli | grep -e Upload: -e Download:)"
 download=$(echo $result | awk '{print $2}')
 download_unit=$(echo $result | awk '{print $3}')  
 upload=$(echo $result | awk '{print $5}')
 upload_unit=$(echo $result | awk '{print $6}')
}

data_fun(){
 [ $users_arg ] && users_fun && echo "wifi users: $users"
 [ $temp_arg ] && temp_fun && echo "temp: $temp'C"
 [ $cpu_arg ] && cpu_fun && echo "cpu: $cpu%"
 [ $ram_arg ] && ram_fun && echo "ram: $ram%"
 [ $storage_arg ] && storage_fun && echo "storage: $storage%"
 [ $network_arg ] && network_fun && echo "Download $download $download_unit " && echo "Upload $upload $upload_unit "
 echo ""

 TIME=$(date  "+%H%M%S%d%m%y") 
 data='{"deployment":'$(jq ".deployment" $conf)',
        "device_id":'$id',
        "date":'$TIME',
        "users":"'$users'",
        "temp":"'$temp'",
        "cpu":"'$cpu'",
        "ram":"'$ram'",
        "storage":"'$storage'",
        "network":{"upload":"'$upload'","upload_unit":"'$upload_unit'","download":"'$download'","download_unit":"'$download_unit'"} }'


}

###### Initialization ######
path="/root/back-end"
log="/etc/mazi"
interval="10"
conf="/etc/mazi/mazi.conf"
domain="localhost"

if [ "$(sh $path/current.sh -w)" = "device OpenWrt router" ];then
   ROUTER="TRUE"
fi

######  Parse command line arguments   ######

while [ $# -gt 0 ]
do
  key="$1"
 
  case $key in
      -u|--users)
      users_arg="TRUE" 
      ;;
      -t|--temp)
      temp_arg="TRUE"
      ;; 
      -c|--cpu)
      cpu_arg="TRUE"
      ;;
      -r|-ram)
      ram_arg="TRUE"
      ;;
      -s|-storage)
      storage_arg="TRUE"
      ;;
      -n|--network)
      network_arg="TRUE"
      interval="60"
      ;;
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
  shift #past argument or value
done


if [ $store ];then 
  if [ $store = "enable" ];then
    id=$(curl -s -X GET -d @$conf http://$domain:4567/device/id)
    [ ! $id ] && id=$(curl -s -X POST -d @$conf http://$domain:4567/deployment/register) 
    curl -s -X POST --data '{"deployment":'$(jq ".deployment" $conf)'}' http://$domain:4567/create/statistics
    data_fun
    curl -s -X POST --data "$data" http://$domain:4567/update/statistics

    while [ true ]; do
      target_time=$(( $(date +%s)  + $interval ))
      data_fun
      current_time=$(date +%s)
      [ $(($target_time - $current_time)) -gt 0 ] && sleep $(($target_time - $current_time)) 
      curl -s -X POST --data "$data" http://$domain:4567/update/statistics   
    done

  elif [ $store = "disable" ];then
    Pid=$(ps aux | grep -F "store enable" | grep -v 'grep' | awk '{print $2}' )
    [ $Pid ] && kill $Pid && echo " disable"
  else
    echo "WRONG ARGUMENT"
    usage
  fi
else
  data_fun
fi


set +x 
