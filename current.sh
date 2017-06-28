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


WRT="10.0.2.2"
PSWD="mazi"
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
  ROUTER="TRUE"
  dev="OpenWrt router"
else
  if [ "$(ps aux | grep hostapd | grep -v 'grep')" ];then
  dev="Raspberry pi"
  fi
fi

## print interface
if [ "$INTERFACE" = "YES" ]; then
  if [ "$ROUTER" ];then
    intface="br-lan"
  else
    intface=$(grep 'interface' /etc/hostapd/hostapd.conf| sed 's/\interface=//g') 
  fi
  echo "interface $intface"
fi

## print channel
if [ "$CHANNEL" = "YES" ]; then
  if [ "$ROUTER" ];then 
    channel=$(sudo sshpass -p "$PSWD" ssh root@$WRT "grep 'channel' /etc/config/wireless | sed 's/option channel//g'| grep -o  [^\']* | xargs")
  else
    channel=$(grep 'channel' /etc/hostapd/hostapd.conf| sed 's/channel=//g') 
  fi
  echo "channel $channel"
fi

## print ssid
if [ "$SSID" = "YES" ]; then
  if [ "$ROUTER" ];then
     ssid=$(sudo sshpass -p "$PSWD" ssh root@$WRT "grep 'ssid' /etc/config/wireless | sed 's/option ssid//g'| grep -o  [^\']* | xargs")
  else
    ssid=$(grep 'ssid' /etc/hostapd/hostapd.conf| sed 's/ssid=//g')  
  fi
  echo "ssid $ssid"
fi


## print new domain
if [ $DOMAIN ]; then
  echo "domain $(grep 'ServerName' /etc/apache2/sites-available/portal.conf | awk '{print $2}')"
fi


## print password if it exists
if [ "$PASSWORD" = "YES" ]; then
  key="-"
  if [ "$ROUTER" ];then
     pswd=$(sudo sshpass -p "$PSWD" ssh root@$WRT "grep 'option encryption' /etc/config/wireless | sed 's/option encryption//g'| grep -o [^\']* | xargs")
     if [ "$pswd" != "none" ];then
         key=$( sudo sshpass -p "$PSWD" ssh root@$WRT "grep 'option key' /etc/config/wireless | sed 's/option key//g'| grep -o [^\']* | xargs")
     fi  
  else
     paswd=$(grep 'wpa_passphrase' /etc/hostapd/hostapd.conf| sed 's/wpa_passphrase=//g')
     if [ "$pswd" != "" ];then
         key=$(grep 'wpa_passphrase' /etc/hostapd/hostapd.conf| sed 's/wpa_passphrase=//g')
     fi
  fi 
  echo "password $key"
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
  echo "device $dev"
fi

