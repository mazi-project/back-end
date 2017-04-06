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
          echo "-u,--users        Display the total online users" 1>&2; exit 1; }



######  Parse command line arguments   ######
path=$(pwd)
key="$1"

case $key in
    -u|--users)
    cd $path
    sudo touch users.log
    sudo chmod 777 users.log 
    sudo arp-scan --interface=wlan0 --localnet --retry=3 -g  > users.log
    users=$(cat users.log | grep 'responded' | awk '{print $12}')
    echo "wifi users" $users 
    ;;
    *)
       # unknown option
    usage   
    ;;
esac
exit 0


#set +x




