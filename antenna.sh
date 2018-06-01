#!/bin/bash  

#The mazi-antenna.sh script has	been created in	order to manage	an external USB	adapter	that is	connected to the Raspberry Pi.
# This	script	is able	to check if a USB adapter is connected to the Raspberry	Pi. In addition, you can discover the available networks
# in range and connect to one of them. Finally,	you can	disconnect the USB adapter from	the connected Wi-Fi network.
#
#set -x
## initialization ##

cd /root/back-end
path="/etc/wpa_supplicant/wpa_supplicant.conf"
wifi_intface=$(bash mazi-current.sh -i wifi | awk '{print $2}')
internet_intface=$(bash mazi-current.sh -i internet | awk '{print $2}')
password=""
ssid=""

usage() { echo "Usage: sudo sh antenna.sh  [options]" 
	  echo ""
          echo "[options]"
          echo " -i,--interface                  Set the interface"
	  echo " -a,--active                     Shows the SSID of the interface" 
          echo " -s,--ssid                       Sets the SSID of the Wi-Fi network"
          echo " -p,--password                   Sets the password of the Wi-Fi network"
          echo " -l,--list                       Displays a list of the available Wi-Fi networks in range"
          echo " -h,--hidden                     Connect to hidden Wi-Fi network"
          echo " -d,--disconnect                 Disconnect the USB adapter from Wi-Fi network " 1>&2; exit 1; 
}
disconnect(){
     sudo sed -i '/network={/d' $path
     sudo sed -i '/ssid=/d' $path
     sudo sed -i '/psk=/d' $path
     sudo sed -i '/key_mgmt=NONE/d' $path
     sudo sed -i '/}/d' $path

     WPAid=$(sudo ps aux | grep wpa_supplicant | grep $1 | awk '{print $2}') 
     [ "$WPAid" ] && sudo kill $WPAid
     killall dhclient
     ip addr flush dev $1
     ifconfig $1 down
     # Delete iptable rule
     sudo iptables -t nat -D POSTROUTING -o $intface -j MASQUERADE
     sudo iptables-save | sudo tee /etc/iptables/rules.v4 >/dev/null

}
list(){
     sudo ifconfig $intface up 
     sudo iwlist $intface scan | grep "ESSID" | uniq
     exit 0;
}
active(){
    echo "active $(iwconfig $intface 2>/dev/null | grep $intface |awk '{print $4}')"
    exit 0;
}
connect(){
    ##exception##
    [ "$wifi_intface" = "$intface" ] && echo "This interface is being used by the Access Point" && exit 0;
    
    ##disconnect previous interface##
    [ "$internet_intface" != "-" ] && disconnect $internet_intface
    disconnect $intface
    ##connect current interface## 
    sudo sed -i '$ a network={' $path
    sudo sed -i "$ a ssid=\"$ssid\" " $path
    [ $password ] && sudo sed -i "$ a psk=\"$password\"" $path || sudo sed -i '$ a key_mgmt=NONE' $path
    [ $hidden ] && sudo sed -i '$ a scan_ssid=1' $path && echo "Hidden"
    sudo sed -i '$ a }' $path
    sudo ifconfig $intface up
    sudo wpa_supplicant -B -i $intface -c /etc/wpa_supplicant/wpa_supplicant.conf 
    dhclient $intface 
    ## Forward internet through interface
    sudo iptables -t nat -A POSTROUTING -o $intface -j MASQUERADE
    sudo iptables-save | sudo tee /etc/iptables/rules.v4 >/dev/null
}


while [ $# -gt 0 ]
do
key="$1"

case $key in
    -i|--interface)
    intface="$2"
    shift # past argument=value
    ;;
    -s|--ssid)
    ssid="$2"
    shift # past argument=value
    ;;
    -p|--password)
    password="$2"
    shift # past argument=value
    ;;
    -a|--active)
    active_arg="TRUE"
    ;;
    -h|--hidden)
    hidden="TRUE"
    ;;
    -l|--list)
    list_arg="TRUE"
    ;;
    -d|--disconnect)
    disconnect_arg="TRUE"
    ;;
    *)
       # unknown option
    usage   
    ;;
esac
shift     #past argument or value
done

[ $disconnect_arg ] && disconnect $intface


#### exceptions ######
if [ -z  $intface ];then
  echo "*****"
  echo "Please fill the interface argument"
  echo "****"
  usage
  exit 0;
else
 device=$(ifconfig $intface 2>/dev/null | grep $intface | awk '{print $1}')
 if [ -z $device ];then
    echo "No such device" 
    exit 0; 
 fi
fi
####################

[ $list_arg ] && list
[ $active_arg ] && active
[ $ssid ] && connect

exit 1;

#set +x

