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
          echo "-s,--storage      Displays the used storage in MB and (%) "
          echo "     [unit]       Units are  KB, MB and GB.( Default is MB )"
          echo "--sd              Displays information of SD card"
          echo "-n,--network      Displays the Download/Upload speed" 
          echo "-d,--domain       Set a remote server domain.( Default is localhost )"
          echo "--store           [enable] , [disable ] or [flush]"   
          echo "--status          Displays the status of store process" 1>&2; exit 1; 
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
      storage=$(df -$unit | grep root | awk '{print $3}'| grep -o '[0-9]*\.*[0-9]*')
      storagePer=$(df -h | grep root | awk '{print $5}'| grep -o '[0-9]*\.*[0-9]*')
}
network_fun(){
 result="$(speedtest-cli | grep -e Upload: -e Download:)"
 download=$(echo $result | awk '{print $2}')
 download_unit=$(echo $result | awk '{print $3}')  
 upload=$(echo $result | awk '{print $5}')
 upload_unit=$(echo $result | awk '{print $6}')
}

SD_fun(){
 SDsize=$(parted /dev/$SDname unit GB print | grep "Disk /dev/$SDname" | awk '{print $NF}')
 size=$(parted /dev/$SDname unit B print | grep "Disk /dev/$SDname" | awk '{print $NF}'|tr -dc '0-9') 
 UseSize=$(parted /dev/$SDname unit B print | awk '/Number/{y=1;next}y' | awk '{print $3}' | sort -h | tail -1 |tr -dc '0-9')
 [ $(expr $size % $UseSize) -le "100" ] && expand="Yes" || expand="No"
 }


data_fun(){
 [ $users_arg ] && users_fun && echo "wifi users: $users"
 [ $temp_arg ] && temp_fun && echo "temp: $temp'C"
 [ $cpu_arg ] && cpu_fun && echo "cpu: $cpu%"
 [ $ram_arg ] && ram_fun && echo "ram: $ram%"
 [ $exp ] && raspi-config --expand-rootfs  &&  echo "The file system have been expanded"
 [ $SDinfo ] && SD_fun && echo "SD size: $SDsize" && echo "expand: $expand"
 [ $storage_arg ] && storage_fun && echo "storage: $storage$unit_form ($storagePer%)"
 [ $network_arg ] && network_fun && echo "Download $download $download_unit " && echo "Upload $upload $upload_unit "
 echo ""

}


store_data(){
 TIME=$(date  "+%H%M%S%d%m%y") 
 data='{"deployment":'$(jq ".deployment" $conf)',
        "device_id":"$id",
        "date":'$TIME',
        "users":"'$users'",
        "temp":"'$temp'",
        "cpu":"'$cpu'",
        "ram":"'$ram'",
        "storage":"'$storagePer'",
        "network":{"upload":"'$upload'","upload_unit":"'$upload_unit'","download":"'$download'","download_unit":"'$download_unit'"} }'


}


status_call() {
  response=$(tac /etc/mazi/rest.log| grep "$1" | awk -v FS="($1:|http_code:)" '{print $2}')
  http_code=$(tac /etc/mazi/rest.log| grep "$1" | head -1 | awk '{print $NF}')
  [ "$http_code" = "200" -a "$response" = " OK " ] && call_st="OK" && error=""
  [ "$http_code" = "000" ] && call_st="ERROR" && error="Connection refused"
  [ "$http_code" = "200" -a "$response" != " OK " ] && call_st="ERROR :" && error="$response"
  [ "$http_code" = "500" ] && call_st="ERROR :" && error="The server encountered an unexpected condition which prevented it from fulfilling the request"

}

###### Initialization ######
path="/root/back-end"
log="/etc/mazi"
interval="60"
conf="/etc/mazi/mazi.conf"
domain="localhost"
SDname=$(lsblk | grep "^mm" | awk '{print $1}')
unit_form="MB"
unit="m"
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
      hardware="TRUE"
      ;; 
      -c|--cpu)
      cpu_arg="TRUE"
      hardware="TRUE"
      ;;
      -r|--ram)
      ram_arg="TRUE"
      hardware="TRUE"
      ;;
      -s|--storage)
      storage_arg="TRUE"
      hardware="TRUE"
        case $2 in
        KB)
        unit="k" && unit_form="KB" && shift 
        ;;
        MB)
        unit="m" && unit_form="MB" && shift
        ;;
        GB)
        unit="h" && unit_form="GB" && shift
        ;;
        esac
      ;;
      -n|--network)
      network_arg="TRUE"
      hardware="TRUE"
      ;;
      --status)
      status="TRUE"
      ;;
      --store)
      store="$2"
      shift
      ;;
      --sd)
      if [ $# -ge 2 ];then
         [ $2 = "expand" ] && exp="TRUE" && shift
      fi
      [ $exp ] || SDinfo="TRUE"
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


if [ $status ];then
  status_call hardware
  [ "$(ps aux | grep "store enable" | grep "mazi-stat.sh" | grep "\-t \|\--temp "| grep -v 'grep')" ] && echo "temperature active" || echo "temperature inactive"   
  [ "$(ps aux | grep "store enable" | grep "mazi-stat.sh" | grep "\-u \|\--users "| grep -v 'grep')" ] && echo "users active" || echo "users inactive"  
  [ "$(ps aux | grep "store enable" | grep "mazi-stat.sh" | grep "\-c \|\--cpu "| grep -v 'grep')" ] && echo "cpu active" || echo "cpu inactive"  
  [ "$(ps aux | grep "store enable" | grep "mazi-stat.sh" | grep "\-r \|\--ram "| grep -v 'grep')" ] && echo "ram active" || echo "ram inactive"  
  [ "$(ps aux | grep "store enable" | grep "mazi-stat.sh" | grep "\-s \|\--storage "| grep -v 'grep')" ] && echo "storage active" || echo "storage inactive"  
  [ "$(ps aux | grep "store enable" | grep "mazi-stat.sh" | grep "\-n \|\--network "| grep -v 'grep')" ] && echo "network active" || echo "network inactive"  
  [ "$(ps aux | grep "store enable" | grep "mazi-stat.sh" | grep -v 'grep')" ] && echo "hardware active $call_st $error" || echo "hardware inactive $call_st $error"
fi

if [ $store ];then 
  id=$(curl -s -X GET -d @$conf http://$domain:4567/device/id)
  [ ! $id ] && id=$(curl -s -X POST -d @$conf http://$domain:4567/monitoring/register) 
  curl -s -X POST http://$domain:4567/create/statistics
  
  if [ $store = "enable" ];then
    [ ! -f /etc/mazi/rest.log -o ! "$(grep -R "hardware:" /etc/mazi/rest.log)" ] && echo "hardware:" >> /etc/mazi/rest.log
    data_fun
    store_data
    [ $hardware ] && response=$(curl -s -w %{http_code} -X POST --data "$data" http://$domain:4567/update/statistics)
    [ $users_arg ] && response=$(curl -s -w %{http_code} -X POST --data "$data" http://$domain:4567/update/users) 
    http_code=$(echo $response | tail -c 4)
    body=$(echo $response| rev | cut -c 4- | rev )
    sed -i "/hardware/c\hardware: $body http_code: $http_code" /etc/mazi/rest.log

    while [ true ]; do
      target_time=$(( $(date +%s)  + $interval ))
      data_fun
      current_time=$(date +%s)
      [ $(($target_time - $current_time)) -gt 0 ] && sleep $(($target_time - $current_time)) 
      store_data
      [ $hardware ] && response=$(curl -s -w %{http_code} -X POST --data "$data" http://$domain:4567/update/statistics)
      [ $users_arg ] && response=$(curl -s -w %{http_code} -X POST --data "$data" http://$domain:4567/update/users)
      http_code=$(echo $response | tail -c 4)
      body=$(echo $response| rev | cut -c 4- | rev )
      sed -i "/hardware/c\hardware: $body http_code: $http_code" /etc/mazi/rest.log

    done

  elif [ $store = "disable" ];then
    Pid=$(ps aux | grep -F "store enable" | grep "mazi-stat.sh" |grep -v 'grep' | awk '{print $2}' )
    [ $Pid ] && kill $Pid && echo " disable"

  elif [ $store = "flush" ];then
    curl -s -X POST --data '{"device_id":'$id'}' http://$domain:4567/flush/statistics  
    curl -s -X POST --data '{"device_id":'$id'}' http://$domain:4567/flush/users 
  else
    echo "WRONG ARGUMENT"
    usage
  fi
else
  data_fun
fi


#set +x 


