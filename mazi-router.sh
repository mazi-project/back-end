#!/bin/bash

usage(){
        echo "mazi-router.sh configures OpenWrt router as external antenna of raspberry pi which broadcasts the local WiFi network mazizone "
        echo "Usage: sh mazi-router.sh [options] " 
        echo ""
        echo "[options]"
        echo "-a,--activate       Starts the process to configure the OpenWrt router "
        echo "-d,--deactivate     Restores the initial settings" 1>&2; exit 1;}


hostapd="/etc/hostapd/hostapd.conf"
path="/etc/dnsmasq.conf"
WRT="10.0.2.2"
PSWD="mazi"
key="$1"
case $key in
    -a |--activate)
    ACT="TRUE"
    shift # past argument=value
    ;;
    -d|--deactivate)
    DACT="TRUE"
    shift # past argument=value
    ;;
    *)
       # unknown option
    usage   
    ;;
esac

if [ "$ACT" ];then
   #Setup eth0 interface and DHCP 
   sudo sed -i '/OpenWrt/d' $path
   sudo sed -i '/interface=eth0/d' $path
   sudo sed -i '/dhcp-range=10.0.2.10,10.0.2.200,255.255.255.0,12h/d' $path
   sudo ifconfig eth0 10.0.2.1/24
   
   sudo sed -i '$ a \#OpenWrt' $path
   sudo sed -i '/#OpenWrt/a \interface=eth0' $path
   sudo sed -i "/interface=eth0/ a \dhcp-range=10.0.2.10,10.0.2.200,255.255.255.0,12h" $path
   sudo service dnsmasq restart
   #Enable WiFi on OpenWrt router
   sshpass -p "$PSWD" ssh root@$WRT 'uci set wireless.@wifi-device[0].disabled=0; uci commit wireless; wifi'
   #Disable WiFi on raspberry pi
   id=$(ps aux | grep hostapd.conf| grep root| awk '{print $2}') 

   if [ "$id" ];then 
      sudo kill $id
   fi

fi


if [ "$DACT" ];then
   #Restore DHCP settings
   sudo sed -i '/OpenWrt/d' $path 
   sudo sed -i '/interface=eth0/d' $path
   sudo sed -i '/dhcp-range=10.0.2.10,10.0.2.200,255.255.255.0,12h/d' $path
   sudo service dnsmasq restart
   
   #Disable WiFi on OpenWrt router
   sudo sshpass -p "$PSWD" ssh root@$WRT 'uci set wireless.@wifi-device[0].disabled=1; uci commit wireless; wifi'

   #Enable WiFi on raspberry pi
   sudo sh /root/back-end/wifiap.sh
fi

