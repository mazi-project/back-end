#!/bin/bash  

#This script modifies a variety of wireless network settings
#
# Usage: sudo sh wifiap.sh  [options]
# 
# [options]
# -i,--interface [wlan0,wlan1]    Set interface name 
# -s,--ssid                       Set the name of your WiFi network
# -c,--channel                    Set channel number
# -p,--password                   Set your passphrase (WiFi password)
# -w,--wpa  [OFF/off]             Turn off wireless network security
# -r,--router                     Modifies the wireless network settings of OpenWrt router

#set -x
usage() { echo "Usage: sudo sh wifiap.sh  [options]" 
          echo " " 
          echo "[options]" 
#          echo "-i,--interface [wlan0,wlan1]    Set interface name"
          echo "-s,--ssid                        Set the name of your WiFi network"
          echo "-c,--channel                     Set channel number"
          echo "-p,--password                    Set your passphrase (WiFi password)"
          echo "-w,--wpa  [OFF/off]              Turn off wireless network security" 1>&2; exit 1; }



path="/etc/hostapd/hostapd.conf"
WRT="10.0.2.2"
PSWD="mazi"
######  Parse command line arguments   ######

while [ $# -gt 0 ]
do
key="$1"

case $key in
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
    *)
     # unknown option
    usage   
    ;;
esac
shift     #past argument or value
done

#Modifies the wireless network settings of OpenWrt router
if [ "$(sh current.sh -w)" = "device OpenWrt router" ];then
   ROUTER="TRUE"
fi


######  First-Time setup  ######

if [ ! -s /etc/hostapd/hostapd.conf ]; then
  
  echo 'driver=nl80211' | sudo tee $path # append line to empty file
  sudo sed -i "$ a hw_mode=g" $path
  sudo sed -i "$ a macaddr_acl=0" $path
fi

######  Setup arguments  ######


#ssid
if [ "$SSID" ]; then
  if [ "$ROUTER" ];then
    sudo sshpass -p "$PSWD" ssh root@$WRT 'sed -i "/option ssid/c\        option ssid '$SSID'" /etc/config/wireless' 
  else
    sudo sed -i '/ssid/d' $path
    sudo sed -i "$ a ssid=$SSID" $path
  fi
fi

#channel
if [ "$CHANNEL" ]; then
  if [ "$ROUTER" ];then
    sudo sshpass -p "$PSWD" ssh root@$WRT 'sed -i "/option channel/c\        option channel '$CHANNEL'" /etc/config/wireless'  
  else
    sudo sed -i '/channel/d' $path
    sudo sed -i "$ a channel=$CHANNEL" $path  
  fi
fi

#password
if [ "$PASSWORD" ];then
  if [ "$ROUTER" ];then  
    #Change password
    sudo sshpass -p "$PSWD" ssh root@$WRT 'sed -i "/option encryption/c\        option encryption 'psk2'" /etc/config/wireless'
    sudo sshpass -p "$PSWD" ssh root@$WRT 'sed -i "/option key/c\        option key '$PASSWORD'" /etc/config/wireless'
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
  if [ "$ROUTER" ];then
    sudo sshpass -p "$PSWD" ssh root@$WRT 'sed -i "/option encryption/c\        option encryption 'none'" /etc/config/wireless'
  else
    sudo sed -i '/wpa/d' $path
    sudo sed -i '/wpa_passphrase/d' $path
    sudo sed -i '/wpa_key_mgmt/d' $path
    sudo sed -i '/wpa_pairwise/d' $path
    sudo sed -i '/wpa_ptk_rekey/d' $path
  fi
fi


###### Restart hostapd.conf ######


if [ "$ROUTER" ];then
  sudo sshpass -p "$PSWD" ssh root@$WRT 'uci set wireless.@wifi-device[0].disabled=1; uci commit wireless; wifi'
  sudo sshpass -p "$PSWD" ssh root@$WRT 'uci set wireless.@wifi-device[0].disabled=0; uci commit wireless; wifi' 
else 
  id=$(ps aux | grep hostapd.conf| grep root| awk '{print $2}') 

  if [ "$id" ];then 
     sudo kill $id
  fi
  sleep 1
  sudo ifconfig $(grep 'interface' /etc/hostapd/hostapd.conf| sed 's/\interface=//g') down
  sudo hostapd -B $path
fi
#set +x

