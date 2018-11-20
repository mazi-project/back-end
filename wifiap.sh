#!/bin/bash  

#The mazi-wifi.sh script is responsible for creating the Wi-Fi Access Point on the Raspberry Pi. With this script, you can 
#also modify the settings of your Wi-Fi Access Point.
cd /root/back-end

## initialization ##
internet_intface=$(bash mazi-current.sh -i internet | awk '{print $2}')
wifi_intface=$(bash mazi-current.sh -i wifi | awk '{print $2}')
hostapd="/etc/hostapd/hostapd.conf"
replace="/etc/hostapd/replace.sed"
WRT="10.0.2.2"
PSWD="mazi"

#Modifies the wireless network settings of OpenWrt router
if [ "$(bash current.sh -w)" = "device OpenWrt router" ];then
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
    wifi_intface=$(bash mazi-current.sh -i wifi | awk '{print $2}')    
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

disable_wpa(){
 [ $ROUTER ] && sudo sshpass -p "$PSWD" ssh root@$WRT 'sed -i "/option encryption/c\        option encryption 'none'" /etc/config/wireless'
 sed -i "/password/c\s/\${password}/-/" $replace
 sed -i '/^wpa/ d' $hostapd
}

stop(){
 if [ $ROUTER ]; then
   sudo sshpass -p "$PSWD" ssh root@$WRT 'uci set wireless.@wifi-device[0].disabled=1; uci commit wireless; wifi'
   /etc/init.d/nodogsplash stop
  else
   id=$(ps aux | grep hostapd.conf| grep -v 'grep' | awk '{print $2}')
   [ "$id" ] && sudo kill $id
   ip addr flush dev $1
   /etc/init.d/nodogsplash stop
 fi
}

start(){
 if [ $ROUTER ];then
    sudo sshpass -p "$PSWD" ssh root@$WRT 'uci set wireless.@wifi-device[0].disabled=0; uci commit wireless; wifi'
 else
  [ "$1" = "$2" ] && sh mazi-antenna.sh -d -i $2
  sudo ifconfig $2 down
  sudo hostapd -B $hostapd &>/dev/null
  sudo ifconfig $2 10.0.0.1/24
 fi
 /etc/init.d/nodogsplash start
}



######  Parse command line arguments   ######

stop $wifi_intface
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
    disable_wpa
    shift # past argument=value
    ;;
    start)
    ### remove wpa ###
    [ "$(cat $replace| grep "password" | cut -d '/' -f 3)" = "-" ] && disable_wpa
    start $internet_intface $wifi_intface
    exit 0;
    ;;
    stop)
    stop $wifi_intface
    exit 0;
    ;;
    restart)
    stop $wifi_intface
    start $internet_intface $wifi_intface
    exit 0;
    ;;
    *)
     # unknown option
    usage   
    exit 0;
    ;;
esac
shift     #past argument or value
done

## Make new hostapd configuration file ##
sed -f /etc/hostapd/replace.sed /etc/hostapd/template_80211n.txt  > /etc/hostapd/hostapd.conf

### remove wpa ###
[ "$(cat $replace| grep "password" | cut -d '/' -f 3)" = "-" ] && disable_wpa
## restart hostapd ##
#stop $wifi_intface
start $internet_intface $wifi_intface




