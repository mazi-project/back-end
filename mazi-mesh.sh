#!/bin/bash
##mesh
#set -x
conf="/etc/mazi/mazi.conf"


usage() { echo "Usage: sudo bash mazi-mesh.sh [Mode] [Options]"
          echo ""
          echo "[Mode]"
          echo "  gateway                      Operates as a gateway node"
          echo "  node                         Operates as a relay node"        
          echo "  portal                       Restore to the Portal settings"
          echo ""
          echo "[gateway Options]"
          echo "  -i, --interface              Set the interface of the mesh network"
          echo "  -s, --ssid                   Set the name of the mesh network"
          echo ""
          echo "[node Options]"
          echo "  -i, --interface              Set the interface of the mesh network"
          echo "  -s, --ssid                   Set the name of the mesh network"
          echo "  -b, --bridgeIface            Set the interface of the Wi-Fi Access Point"1>&2; exit 1; }


batIface(){
  ifaces=$(netstat -i |  awk '{print $1}' | grep -v "Kernel" | grep -v "Iface")
  read -a ifaces <<<$ifaces
  for i in ${ifaces[@]};do
     [ "$(iwconfig $i 2>/dev/null | grep Cell | awk '{print $NF}')" = "02:12:34:56:78:9A" ] && iface=$i
  done
}

gateway(){
 cd /root/back-end
 [ $(jq ".mesh" $conf) = '"gateway"' ] && exit 0;
 sh mazi-antenna.sh -d
 ip link set mtu 1532 dev $iface
 sleep 1
 ifconfig $iface down
 iwconfig $iface mode ad-hoc essid $ssid ap 02:12:34:56:78:9A channel 1
 ifconfig $iface up
 batctl if add $iface
 ip link set up dev $iface
 ip link set up dev bat0
 ifconfig bat0 192.168.1.1
 ### configure /etc/hosts ####
 domain=$(sh mazi-current.sh -d | awk '{print $NF}')
 echo "192.168.1.1     $domain" >> /etc/hosts
 echo "192.168.1.1     local.mazizone.eu"  >> /etc/hosts
 ### configure dnsmasq for mesh interface ####
 echo "interface=bat0" >> /etc/dnsmasq.conf
 echo "dhcp-range=192.168.1.10,192.168.1.200,255.255.255.0,12h" >> /etc/dnsmasq.conf
 service dnsmasq restart
 batctl gw_mode server
 batctl bl 1
 echo $(cat $conf | jq '.+ {"mesh": "gateway"}') | sudo tee $conf
}

node(){
  cd /root/back-end
  ifconfig $iface up
  if [ -z "$(iwlist $iface scan | grep -w '.*"'$ssid'"' )" ];then
   echo "Bad mesh signal"
   exit 0;
  fi  
  sh mazi-antenna.sh -d
  service mazi-portal stop
  service dnsmasq stop
  ip link set mtu 1532 dev $iface
  sleep 1
  ifconfig $iface down
  iwconfig $iface mode ad-hoc essid $ssid ap 02:12:34:56:78:9A channel 1
  ifconfig $iface up
  batctl if add $iface
  ip link set up dev $iface
  ip link set up dev bat0
  batctl gw_mode client
  killall  dhclient
  service dhcpcd stop  

  if [ $br_iface ];then 
     ip link add name br0 type bridge
     mac=$(ifconfig br0 | grep HWaddr | awk '{print $NF}')
     ip link set dev $br_iface master br0
     ip link set dev bat0 master br0
     ifconfig br0 hw ether $mac
     ip link set up dev $br_iface
     ip link set up dev bat0
     ip link set up dev br0
  fi
  batctl gw_mode client
  batctl bl 1

  [ $br_iface ] && sudo dhclient  br0 || sudo dhclient bat0
  id=$(ps aux | grep hostapd.conf| grep -v 'grep' | awk '{print $2}') 
  [ "$id" ] && sudo kill $id
  sleep 1
  sudo hostapd -B /etc/hostapd/hostapd.conf
  echo $(cat $conf | jq '.+ {"mesh": "node"}') | sudo tee $conf
 
}
portal(){
 cd /root/back-end
 if [ $(jq ".mesh" $conf) = '"node"' ];then
    killall  dhclient
    ip link set down dev br0
    ip link delete br0
    ip link set down dev bat0
    ip link set down dev $iface
    batctl if del $iface
    ip link set mtu 1500 dev $iface
    sudo service mazi-portal restart
    sudo service dnsmasq restart
    sudo service dhcpcd restart
    sh mazi-wifi.sh
    echo $(cat $conf | jq '.+ {"mesh": "portal"}') | sudo tee $conf
  elif [ $(jq ".mesh" $conf) = '"gateway"' ];then
    killall  dhclient
    ip link set down dev bat0
    ip link set down dev $iface
    batctl if del $iface
    ip link set mtu 1500 dev $iface
    ## remove mesh configutarion from /etc/hosts ##
    sudo sed -i '/192.168.1.1/d' /etc/hosts
    ## remove mesh configuration from dnsmaq.conf ##
    sudo sed -i '/interface=bat0/d' /etc/dnsmasq.conf
    sudo sed -i '/dhcp-range=192.168.1.10,192.168.1.200,255.255.255.0,12h/d' /etc/dnsmasq.conf
    sudo service dnsmasq restart 
    sh mazi-wifi.sh
    echo $(cat $conf | jq '.+ {"mesh": "portal"}') | sudo tee $conf
  fi
}

case $1 in
     gateway)
        while [ $# -gt 1 ];do
        key="$2"
        case $key in 
        -s|--ssid)
        ssid="$3"
        shift
        ;;
        -i|--interface)
        iface="$3"
        shift
        ;;
        *)
        usage
        ;;
        esac
        shift
        done
     gateway
     ;;
     node)
        while [ $# -gt 1 ];do
        key="$2"
        case $key in 
        -s|--ssid)
        ssid="$3"
        shift
        ;;
        -i|--interface)
        iface="$3"
        shift
        ;;
        -b|--bridgeIface)
        br_iface="$3"
        shift
        ;;
        *)
        usage
        ;;
        esac
        shift
        done
     node
     ;;
     portal)
     echo "portal node"
     batIface
     portal
     ;;
     *)
     usage
     ;;
esac



#set +x




