#!/bin/bash  

#This script returns the current network settings
#
# Usage: sudo sh current.sh  [options]
# 
# [options]
# -i,--interface [wlan0,wlan1]    Print interface  
# -s,--ssid                       Print name of your WIFI network
# -c,--channel                    Print channel number
# -p,--password                   Print WiFi password
# -m,--mode                       Print MAZI zone mode

usage() { echo "Usage: sudo sh current.sh  [options]" 
          echo " " 
          echo "[options]" 
          echo "-i,--interface [wlan0,wlan1]    Displays the interface name"
          echo "-s,--ssid                       Displays the name of your WIFI network"
          echo "-c,--channel                    Displays the number of channel"
          echo "-p,--password                   Displays the WiFi password"
          echo "-d,--domain                     Displays the new domain of toolkit"
          echo "-m,--mode                       Displays the network mode"
          echo "-w,--wifi                       Displays the device which broadcast the local WiFi network" 1>&2; exit 1; }


while [ $# -gt 0 ]
do
key="$1"

case $key in
    -i |--interface)
    INTERFACE="YES"
    ;;
    -d |--domain)
    DOMAIN="YES"
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
    -w|--wifi)
    DEVICE="TRUE"
    ;;
    *)
       # unknown option
    usage   
    ;;
esac
shift #past argument
done


if [ -f /etc/mazi/router.conf  -a  "$(cat /etc/mazi/router.conf)" = "active" ];then
  dev="OpenWrt router"
else
  if [ "$(ps aux | grep hostapd | grep -v 'grep')" ];then
  dev="Raspberry pi"
  fi
fi

## print interface
if [ "$INTERFACE" = "YES" ]; then
  echo "interface $(grep 'interface' /etc/hostapd/hostapd.conf| sed 's/\interface=//g') "  
    
fi

## print channel
if [ "$CHANNEL" = "YES" ]; then
   
   echo "channel $(grep 'channel' /etc/hostapd/hostapd.conf| sed 's/channel=//g')" 
fi

## print ssid
if [ "$SSID" = "YES" ]; then
    
  echo "ssid $(grep 'ssid' /etc/hostapd/hostapd.conf| sed 's/ssid=//g')"  
fi
## print new domain
if [ $DOMAIN ]; then

  echo $(grep 'ServerName' /etc/apache2/sites-available/portal.conf | awk '{print $2}')
fi

## print password if it exists
if [ "$PASSWORD" = "YES" ]; then
   if [ "$(grep 'wpa_passphrase' /etc/hostapd/hostapd.conf| sed 's/wpa_passphrase=//g')" ];then
     echo "password $(grep 'wpa_passphrase' /etc/hostapd/hostapd.conf| sed 's/wpa_passphrase=//g')"
   else
     echo "password -"
   fi 
fi

## print mode
if [ "$MODE" = "YES" ]; then
   if [ -f /etc/mazi/mazi.conf ]; then
     echo "mode $(cat /etc/mazi/mazi.conf) "
   else
     echo "mode -"
   fi 
fi



if [ "$DEVICE" ];then
  echo "$dev"
fi

