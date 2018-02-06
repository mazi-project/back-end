#!/bin/bash
#The mazi-router.sh script is used for the management of the OpenWrt Router connected to this MAZI Zone. After connecting an OpenWrt router
# this	script	is able	to detect it and control the status of the connection, (activate/deactivate).

#set -x
usage(){
        echo "Usage: sh mazi-router.sh [options] " 
        echo ""
        echo "[options]"
        echo "-s,--status         Displays if the OpenWRT router exists"
        echo "-a,--activate       Activates the OpenWRT router as the Wi-Fi AP of this MAZI Zone "
        echo "-d,--deactivate     Discannects the router and restores the initial settings of the Raspberry pi built-in Wi-Fi module" 1>&2; exit 1;}


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
   
   sudo sed -i '/auto eth0/ a \iface eth0 inet static\n  address 10.0.2.1\/24' $interface

   #Setup Dnsmasq
   sudo sed -i '/OpenWrt/d' $path
   sudo sed -i '/interface=eth0/d' $path
   sudo sed -i '/dhcp-range=10.0.2.10,10.0.2.200,255.255.255.0,12h/d' $path

   sudo sed -i '$ a \#OpenWrt' $path
   sudo sed -i '/#OpenWrt/a \interface=eth0' $path
   sudo sed -i "/interface=eth0/ a \dhcp-range=10.0.2.10,10.0.2.200,255.255.255.0,12h" $path
   sudo service dnsmasq restart
   
   #Setup remote AP
   ssid=$(sh /root/back-end/mazi-current.sh -s | awk '{print $NF}') 
   channel=$(sh /root/back-end/mazi-current.sh -c | awk '{print $NF}') 
   password=$(sh /root/back-end/mazi-current.sh -p | awk '{print $NF}')
   sudo sshpass -p "$PSWD" ssh root@$WRT 'sed -i "/option channel/c\        option channel '$channel'" /etc/config/wireless'  
   sudo sshpass -p "$PSWD" ssh root@$WRT 'sed -i "/option ssid/c\        option ssid '$ssid'" /etc/config/wireless'
   if [ "$password" != "-" ];then
       sudo sshpass -p "$PSWD" ssh root@$WRT 'sed -i "/option encryption/c\        option encryption 'psk2'" /etc/config/wireless'
       sudo sshpass -p "$PSWD" ssh root@$WRT 'sed -i "/option key/c\        option key '$password'" /etc/config/wireless' 
   else
       sudo sshpass -p "$PSWD" ssh root@$WRT 'sed -i "/option encryption/c\        option encryption 'none'" /etc/config/wireless'
   fi
 
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
   sudo sed -i '/iface eth0/,/address 10.0.2.1\/24/d' $interface
   sudo sed -i '/auto eth0/ a \iface eth0 inet manual' $interface

fi
#set +x
