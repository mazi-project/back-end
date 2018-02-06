#!/bin/bash  

#The mazi-antenna.sh script has	been created in	order to manage	an external USB	adapter	that is	connected to the Raspberry Pi.
# This	script	is able	to check if a USB adapter is connected to the Raspberry	Pi. In addition, you can discover the available networks
# in range and connect to one of them. Finally,	you can	disconnect the USB adapter from	the connected Wi-Fi network.
#


usage() { echo "Usage: sudo sh antenna.sh  [options]" 
	  echo ""
          echo "[options]"
	  echo " -a,--active                     Shows if a USB Wi-Fi adapter exists" 
          echo " -s,--ssid                       Sets the SSID of the Wi-Fi network"
          echo " -p,--password                   Sets the password of the Wi-Fi network"
          echo " -l,--list                       Displays a list of the available Wi-Fi networks in range"
          echo " -h,--hidden                     Connect to hidden Wi-Fi network"
          echo " -d,--disconnect                 Disconnect the USB adapter from Wi-Fi network " 1>&2; exit 1; }


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
        sudo sed -i '/network={/d' $path
        sudo sed -i '/ssid=/d' $path
        sudo sed -i '/psk=/d' $path
        sudo sed -i '/key_mgmt=NONE/d' $path
        sudo sed -i '/}/d' $path

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

