#!/bin/bash  

#This script returns the current network settings
#
# Usage: sudo mazi-current.sh  [options]
# 
# [options]
# -i,--interface [wlan0,wlan1]    Print interface  
# -s,--ssid                       Print name of your WIFI network
# -c,--channel                    Print channel number
# -p,--password                   Print WiFi password
# -m,--mode                       Print MAZI zone mode

usage() { echo "Usage: sudo  mazi-current.sh  [options]" 
          echo " " 
          echo "[options]" 
          echo "-i,--interface [wlan0,wlan1]    Print the interface name"
          echo "-s,--ssid                       Print the name of your WIFI network"
          echo "-c,--channel                    Print the number of channel"
          echo "-p,--password                   Print the WiFi password"
          echo "-m,--mode                       Print the network mode" 1>&2; exit 1; }


path_hostapd="/etc/hostapd/hostapd.conf"
mazi_conf="/etc/mazi/mazi.conf"
while [ $# -gt 0 ]
do
key="$1"

case $key in
    -i |--interface)
    INTERFACE="YES"
    ;;
    -s|--ssid)
    SSID="YES"
    ;;
    -c|--channe)
    CHANNEL="YES"
    ;;
    -p|--password)
    PASSWORD="YES"
    ;;
    -m|--mode)
    MODE="YES"
    ;;
    *)
       # unknown option
    usage   
    ;;
esac
shift #past argument
done

## print interface
if [ $INTERFACE ]; then
  echo "interface $(grep 'interface' $path_hostapd | sed 's/\interface=//g') "  
    
fi

## print channel
if [ $CHANNEL ]; then
   
   echo "channel $(grep 'channel' $path_hostapd | sed 's/channel=//g')" 
fi

## print ssid
if [ $SSID ]; then
    
  echo "ssid $(grep 'ssid' $path_hostapd | sed 's/ssid=//g')"  
fi

## print password if it exists
if [ $PASSWORD ]; then
   if [ "$(grep 'wpa_passphrase' $path_hostapd | sed 's/wpa_passphrase=//g')" ];then
     echo "password $(grep 'wpa_passphrase' $path_hostapd | sed 's/wpa_passphrase=//g')"
   else
     echo "password -"
   fi 
fi

## print mode
if [ $MODE ]; then
   if [ -f $mazi_conf ]; then
     echo "mode $(cat $mazi_conf) "
   else
     echo "mode -"
   fi 
fi




