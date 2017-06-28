#!/bin/bash  

#This script displays the total online users in the local network 
#
# Usage: sudo sh mazi-stat.sh  [options]
# 
# [options]
# -u,--users     Display online users 
#

#set -x
usage() { echo "Usage: sudo sh mazi-stat.sh  [options]" 
          echo " " 
          echo "[options]"
          echo "-t,--temp         Displays the CPU core temperature" 
          echo "-u,--users        Displays the total online users"
          echo "-c,--cpu          Displays the CPU usage" 
          echo "-r,--ram          Displays the RAM usage"
          echo "-s,--storage      Displays the percentage of used storage"
          echo "-n,--network      Displays the Download/Upload speed" 1>&2; exit 1; }



######  Parse command line arguments   ######
path=$(pwd)
key="$1"

if [ "$(sh current.sh -w)" = "device OpenWrt router" ];then
   ROUTER="TRUE"
fi


case $key in
    -u|--users)
    cd $path
    sudo touch users.log
    sudo chmod 777 users.log 
    if [ "$ROUTER" ];then
      sudo arp-scan --interface=eth0 10.0.2.1/24 --retry=3 -g  > users.log
      users=$(cat users.log | grep 'responded' | awk '{print $12}') 
      echo "wifi users $(($users - 1))"
    else
      sudo arp-scan --interface=wlan0 10.0.0.1/24 --retry=3 -g  > users.log
      users=$(cat users.log | grep 'responded' | awk '{print $12}')
      echo "wifi users" $users    
    fi
    ;;
    -t|--temp)
    vcgencmd measure_temp
    ;; 
    -c|--cpu)
    top -d 1 -b -n2 | grep "Cpu(s)"|tail -n 1 | awk '{print ($2 + $4)"%"}'
    ;;
    -r|-ram)
    free -k | grep Mem | awk '{printf"%3.1f%%\n",($3/$2*100)}'
    ;;
    -s|-storage)
    df -h | grep root | awk '{print $5}'
    ;;
    -n|--network)
    speedtest-cli | grep -e Upload: -e Download:
    ;;
    *)
       # unknown option
    usage   
    ;;
esac
exit 0


#set +x




