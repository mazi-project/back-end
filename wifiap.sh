#!/bin/bash  

#This script modify a variety of wireless network settings
#
# Usage: sudo sh wifiap.sh  [options]
# 
# [options]
# -i,--interface [wlan0,wlan1]    Set interface name 
# -s,--ssid                       Set the name of your WiFi network
# -c,--channel                    Set channel number
# -p,--password                   Set your passphrase (WiFi password)
# -w,--wpa  [OFF/off]             Turn off wireless network security
#

#set -x
usage() { echo "Usage: sudo sh wifiap.sh  [options]" 
          echo " " 
          echo "[options]" 
#          echo "-i,--interface [wlan0,wlan1]    Set interface name"
          echo "-s,--ssid                       Set the name of your WiFi network"
          echo "-c,--channel                    Set channel number"
          echo "-p,--password                   Set your passphrase (WiFi password)"
          echo "-w,--wpa  [OFF/off]             Turn off wireless network security" 1>&2; exit 1; }



path="/etc/hostapd/hostapd.conf"

######  Parse command line arguments   ######

while [ $# -gt 0 ]
do
key="$1"

case $key in
#    -i |--interface)
#    INTERFACE="$2"
#    shift # past argument=value
#    ;;
    -s|--ssid)
    SSID="$2"
    shift # past argument=value
    ;;
    -c|--channel)
    CHANNEL="$2"
    shift # past argument=value
    ;;
    -p|--password)
    PASSWORD="$2"
    shift # past argument=value
    ;;
    -w|--wpa)
    WPA="$2"
    shift # past argument=value
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


######  First-Time setup  ######

if [ ! -s /etc/hostapd/hostapd.conf ]; then
  
  echo 'driver=nl80211' | sudo tee $path # append line to empty file
  sudo sed -i "$ a hw_mode=g" $path
  sudo sed -i "$ a macaddr_acl=0" $path
fi

######  Setup arguments  ######

#interface
#if [ "$INTERFACE" ]; then
#  
#  sudo sed -i '/interface/d' $path
#  sudo sed -i "$ a interface=$INTERFACE" $path  
#fi

#ssid
if [ "$SSID" ]; then
  
  sudo sed -i '/ssid/d' $path
  sudo sed -i "$ a ssid=$SSID" $path  
fi

#channel
if [ "$CHANNEL" ]; then
  
  sudo sed -i '/channel/d' $path
  sudo sed -i "$ a channel=$CHANNEL" $path  
fi

#password
if [ "$PASSWORD" ];then
  if [ $(grep 'wpa' /etc/hostapd/hostapd.conf | wc -l) -eq 5  ];then  
    #Change password
    sudo sed -i '/wpa_passphrase/d' $path
    sudo sed -i "$ a wpa_passphrase=$PASSWORD" $path   
  else
    #Set up wireless network security
    sudo sed -i '/wpa/d' $path
    sudo sed -i '/wpa_passphrase/d' $path
    sudo sed -i '/wpa_key_mgmt/d' $path
    sudo sed -i '/wpa_pairwise/d' $path
    sudo sed -i '/wpa_ptk_rekey/d' $path
   
    sudo sed -i '$ a wpa=1' $path
    sudo sed -i "$ a wpa_passphrase=$PASSWORD" $path
    sudo sed -i '$ a wpa_key_mgmt=WPA-PSK' $path
    sudo sed -i '$ a wpa_pairwise=TKIP CCMP' $path
    sudo sed -i '$ a wpa_ptk_rekey=600' $path

  fi
fi

######  Turn off wireless network security  #######

if [ "$WPA" = "off" -o "$WPA" = "OFF" ];then
    sudo sed -i '/wpa/d' $path
    sudo sed -i '/wpa_passphrase/d' $path
    sudo sed -i '/wpa_key_mgmt/d' $path
    sudo sed -i '/wpa_pairwise/d' $path
    sudo sed -i '/wpa_ptk_rekey/d' $path

fi


###### Restart hostapd.conf ######

id=$(ps aux | grep hostapd.conf| grep root| awk '{print $2}') 

if [ "$id" ];then 
   sudo kill $id
fi
sudo ifconfig $(grep 'interface' /etc/hostapd/hostapd.conf| sed 's/\interface=//g') down
sudo hostapd -B $path

#set +x




