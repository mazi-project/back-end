#!/bin/bash  

#This script set up the second antenna 
#
# Usage: sudo sh antenna.sh  [options]
# 
# [options]
# -a,--active                     Displays if we have second wifi dongle antena 
# -s,--ssid                       Set the name of  WIFI network
# -p,--password                   Set the password of WIFI network
#


usage() { echo "Usage: sudo sh antenna.sh  [options]" 
	  echo ""
          echo "[options]"
	  echo " -a,--active                     Displays if we have second wifi dongle antena" 
          echo " -s,--ssid                       Set the name of  WIFI network"
          echo " -p,--password                   Set the password of WIFI network"
          echo " -l,--list                       Displays the list of available wifi"
          echo " -h,--hidden                     Connect to hidden network"
          echo " -d,--disconnect                 Disconnect from network " 1>&2; exit 1; }


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
    -h|--hidden)
    hidden="TRUE"
    ;;
    -l|--list)
    list="TRUE"
    ;;
    -d|--disconnect)
    disc="TRUE"
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


if [ $disc ]; then
        WPAid=$(sudo ps aux | grep wpa_supplicant | awk '{print $2}')
        DHCPid=$(sudo ps aux | grep "dhcpcd $intface"| awk '{print $2}')      
        if [ "$WPAid" ];then 
           sudo kill $WPAid
        fi
         if [ "$DHCPid" ];then 
           sudo kill $DHCPid
        fi
fi

if [ "$list" = "TRUE" ];then
      sudo iwlist $intface scan | grep "ESSID" | uniq
      exit 0;
fi



if [ $active ];then
      if [ $intface ];then
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
        sudo sed -i '/key_mgmt=NONE/d' $path
	sudo sed -i '/}/d' $path

	sudo sed -i '$ a network={' $path
	sudo sed -i "$ a ssid=\"$ssid\" " $path
	if [ "$password" ];then
           sudo sed -i "$ a psk=\"$password\"" $path
	else
           sudo sed -i '$ a key_mgmt=NONE' $path
        fi
        if [ $hidden ];then
           sudo sed -i '$ a scan_ssid=1' $path
           echo "Hidden"
        fi
        sudo sed -i '$ a }' $path

	WPAid=$(sudo ps aux | grep wpa_supplicant | awk '{print $2}')
        DHCPid=$(sudo ps aux | grep "dhcpcd $intface"| awk '{print $2}')      
        if [ "$WPAid" ];then 
           sudo kill $WPAid
        fi
         if [ "$DHCPid" ];then 
           sudo kill $DHCPid
        fi
        sleep 1
        sudo ifconfig $intface up
      # sudo wpa_supplicant -B -i$intface -c /etc/wpa_supplicant/wpa_supplicant.conf -Dwext
        sudo wpa_supplicant -B -i $intface -c /etc/wpa_supplicant/wpa_supplicant.conf
        dhcpcd $intface
fi




exit 1;

