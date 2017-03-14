#!/bin/bash  

#This script set up the second antenna 
#
# Usage: sudo sh antenna.sh  [options]
# 
# [options]
# -a,--active                     Displays if ACTIVE if we have second antena 
# -s,--ssid                       Set the name of  WIFI network
# -p,--password                   Set the password of WIFI network
#



usage() { echo "Usage: sudo sh antenna.sh  [options]" 
	  echo ""
          echo "[options]"
	  echo " -a,--active                     Displays if ACTIVE if we have second antena" 
          echo " -s,--ssid                       Set the name of  WIFI network"
          echo " -p,--password                   Set the password of WIFI network"1>&2; exit 1; }


path="/etc/wpa_supplicant/wpa_supplicant.conf"
intface=$(ifconfig | grep "wlan1" | awk '{print $1}')
password=""
ssid=""


while [ $# -gt 0 ]
do
key="$1"

case $key in
    -s|--ssid)
    ssid="$2"
    shift # past argument=value
    ;;
    -p|--password)
    password="$2"
    shift # past argument=value
    ;;
    -a|--active)
    active="TRUE"
    ;;
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
       # unknown option
    usage   
    ;;
esac
shift     #past argument or value
done

intface=$(iwconfig wlan1 | grep "wlan1" | awk '{print $1}')


if [ "$active" = "TRUE" ];then
      if [ "$intface" ];then
         
         echo "active $(iwconfig wlan1 | grep wlan1 |awk '{print $4}')"
      else
         echo "inactive"
      fi
      exit 0;
fi

if [ "$ssid" ];then
	
	sudo sed -i '/network={/d' $path
	sudo sed -i '/ssid=/d' $path
	sudo sed -i '/psk=/d' $path
	sudo sed -i '/}/d' $path

	sudo sed -i '$ a network={' $path
	sudo sed -i "$ a ssid=\"$ssid\" " $path
	if [ "$password" ];then
           sudo sed -i "$ a psk=\"$password\"" $path
	fi
        sudo sed -i '$ a }' $path

	id=$(sudo ps aux | grep wpa_supplicant | awk '{print $2}') 

        if [ "$id" ];then 
           sudo kill $id
        fi
        sleep 1
        sudo ifconfig $intface up
        sudo wpa_supplicant -B -i$intface -c /etc/wpa_supplicant/wpa_supplicant.conf -Dwext
        
 
fi




exit 1;

