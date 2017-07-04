#!/bin/bash
#set -x
usage(){
        echo "mazi-router.sh configures OpenWrt router as external antenna of raspberry pi which broadcasts the local WiFi network mazizone "
        echo "Usage: sh mazi-router.sh [options] " 
        echo ""
        echo "[options]"
        echo "-s,--status         Displays the status of router OpenWrt"
        echo "-a,--activate       Starts the process to configure the OpenWrt router "
        echo "-d,--deactivate     Restores the initial settings" 1>&2; exit 1;}


hostapd="/etc/hostapd/hostapd.conf"
interface="/etc/network/interfaces"
path="/etc/dnsmasq.conf"
WRT="10.0.2.2"
PSWD="mazi"
key="$1"
sudo touch /etc/mazi/router.conf
case $key in
    -a |--activate)
    ACT="TRUE"
    shift # past argument=value
    ;;
    -d|--deactivate)
    DACT="TRUE"
    shift # past argument=value
    ;;
    -s|--status)
    SCAN="TRUE"
    ;;
    *)
       # unknown option
    usage   
    ;;
esac


if [ "$SCAN" ];then
  router=$(sudo arp-scan --interface=eth0 10.0.2.0/24 --arpspa 10.0.2.1 | grep -w "10.0.2.2" | awk '{print $1}')
  if [ "$router" = "10.0.2.2" ];then
     echo "router available"
  else
     echo "router unavailable"
  fi
  exit 0
fi


if [ "$ACT" ];then
   #Setup eth0 interface 
   sudo ifconfig eth0 10.0.2.1/24 
   sudo sed -i '/iface eth0 inet manual/d' $interface
   
   sudo sed -i '/auto eth0/ a \iface eth0 inet static\n  address 10.0.2.1\n  netmask 255.255.255.0\n  gateway 10.0.2.1' $interface

   #Setup Dnsmasq
   sudo sed -i '/OpenWrt/d' $path
   sudo sed -i '/interface=eth0/d' $path
   sudo sed -i '/dhcp-range=10.0.2.10,10.0.2.200,255.255.255.0,12h/d' $path

   sudo sed -i '$ a \#OpenWrt' $path
   sudo sed -i '/#OpenWrt/a \interface=eth0' $path
   sudo sed -i "/interface=eth0/ a \dhcp-range=10.0.2.10,10.0.2.200,255.255.255.0,12h" $path
   sudo service dnsmasq restart
  
   #Enable WiFi on OpenWrt router
   sshpass -p "$PSWD" ssh root@$WRT 'uci set wireless.@wifi-device[0].disabled=0; uci commit wireless; wifi'
   #Disable WiFi on raspberry pi
   id=$(ps aux | grep hostapd.conf| grep -v 'grep' | awk '{print $2}') 

   if [ "$id" ];then 
      sudo kill $id
   fi
   sudo echo 'active' | sudo tee /etc/mazi/router.conf

fi


if [ "$DACT" ];then

  #Enable WiFi on raspberry pi
   id=$(ps aux | grep hostapd.conf| grep -v 'grep'| awk '{print $2}') 

   if [ "$id" = "" ];then 
     sudo ifconfig wlan0 down
     sudo hostapd -B $hostapd
   fi
   sudo ifconfig wlan0 10.0.0.1/24
  #Disable WiFi on OpenWrt router
   sudo sshpass -p "$PSWD" ssh root@$WRT 'uci set wireless.@wifi-device[0].disabled=1; uci commit wireless; wifi'

  #Restore DHCP settings
   sudo sed -i '/OpenWrt/d' $path 
   sudo sed -i '/interface=eth0/d' $path
   sudo sed -i '/dhcp-range=10.0.2.10,10.0.2.200,255.255.255.0,12h/d' $path
   sudo service dnsmasq restart

   sudo echo 'inactive' | sudo tee /etc/mazi/router.conf

   sudo ip addr flush dev eth0
   sudo sed -i '/iface eth0/,/gateway 10.0.2.1/d' $interface
   sudo sed -i '/auto eth0/ a \iface eth0 inet manual' $interface

fi
#set +x
