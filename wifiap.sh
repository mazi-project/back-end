#!/bin/bash  

#The mazi-wifi.sh script is responsible for creating the Wi-Fi Access Point on the Raspberry Pi. With this script, you can 
#also modify the settings of your Wi-Fi Access Point.
set -x
cd /root/back-end

## initialization ##
hostapd="/etc/hostapd/hostapd.conf"
replace="/etc/hostapd/replace.sed"
WRT="10.0.2.2"
PSWD="mazi"

#Modifies the wireless network settings of OpenWrt router
if [ "$(sh current.sh -w)" = "device OpenWrt router" ];then
   ROUTER="TRUE"
fi


usage() { echo "Usage: sudo sh wifiap.sh  [options]" 
          echo " " 
          echo "[options]" 
          echo "-i,--interface                   Set the interface"
          echo "-s,--ssid                        Set the name of the Wi-Fi network"
          echo "-c,--channel                     Set the Wi-Fi channel"
          echo "-p,--password                    Set the Wi-Fi password"
          echo "-w,--wpa  [OFF/off]              Turn off wireless network security" 1>&2; exit 1; 
}

interface(){
 if [ -z $ROUTER ];then
    sed -i "/intface/c\s/\${intface}/$intface/" $replace
    sed -i "/# MAZI configuration/!b;n;cinterface=$intface" /etc/dnsmasq.conf    
    sudo service dnsmasq restart
 fi
}

ssid(){
 [ $ROUTER ] && sudo sshpass -p "$PSWD" ssh root@$WRT 'sed -i "/option ssid/c\        option ssid '$ssid'" /etc/config/wireless' 
 sed -i "/ssid/c\s/\${ssid}/$ssid/" $replace
}

channel(){
 [ $ROUTER ] && sudo sshpass -p "$PSWD" ssh root@$WRT 'sed -i "/option channel/c\        option channel '$channel'" /etc/config/wireless'  
 sed -i "/channel/c\s/\${channel}/$channel/" $replace
}

password(){
 [ $ROUTER ] && sudo sshpass -p "$PSWD" ssh root@$WRT 'sed -i "/option encryption/c\        option encryption 'psk2'" /etc/config/wireless && sed -i "/option key/c\        option key '$password'" /etc/config/wireless'
 sed -i "/password/c\s/\${password}/$password/" $replace
}

disapble_wpa(){
 [ $ROUTER ] && sudo sshpass -p "$PSWD" ssh root@$WRT 'sed -i "/option encryption/c\        option encryption 'none'" /etc/config/wireless'
 sed -i '/^wpa/ d' $hostapd
}

stop(){
 [ $ROUTER ] && sudo sshpass -p "$PSWD" ssh root@$WRT 'uci set wireless.@wifi-device[0].disabled=1; uci commit wireless; wifi'
 id=$(ps aux | grep hostapd.conf| grep -v 'grep' | awk '{print $2}')
 [ "$id" ] && sudo kill $id
}

start(){
 if [ $ROUTER ];then
    sudo sshpass -p "$PSWD" ssh root@$WRT 'uci set wireless.@wifi-device[0].disabled=0; uci commit wireless; wifi'
 else
  [ "$internet_intface" = "$wifi_intface" ] && sh mazi-antenna.sh -d -i $wifi_intface
  sudo ifconfig $wifi_intface down
  sudo hostapd -B $hostapd
  sudo ifconfig $wifi_intface 10.0.0.1/24
 fi
}


######  Parse command line arguments   ######
while [ $# -gt 0 ]
do
key="$1"

case $key in
    -i|--interface)
    intface="$2"
    interface
    shift # past argument=value
    ;;
    -s|--ssid)
    ssid="$2"
    ssid
    shift # past argument=value
    ;;
    -c|--channel)
    channel="$2"
    channel
    shift # past argument=value
    ;;
    -p|--password)
    password="$2"
    password
    shift # past argument=value
    ;;
    -w|--wpa)
    wpa="$2"
    shift # past argument=value
    ;;
    start)
    start
    ;;
    stop)
    stop
    ;;
    restart)
    stop
    start
    ;;
    *)
     # unknown option
    usage   
    ;;
esac
shift     #past argument or value
done

internet_intface=$(sh mazi-current.sh -i internet | awk '{print $2}')
wifi_intface=$(sh mazi-current.sh -i wifi | awk '{print $2}')
sed -f /etc/hostapd/replace.sed /etc/hostapd/template_80211n.txt  > /etc/hostapd/hostapd.conf
[ -z $password ] && sed -i '/^wpa/ d' /etc/hostapd/hostapd.conf
stop
start

set +x



