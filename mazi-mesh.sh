#!/bin/bash
##mesh
#set -x

## initialization ##
gateway="192.168.1.1"
port="7654"
conf="/etc/mazi/mazi.conf"
wifi_intface=$(bash /root/back-end/mazi-current.sh -i wifi | awk '{print $2}')
internet_intface=$(bash /root/back-end/mazi-current.sh -i internet | awk '{print $2}')

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
          echo "[portal Option]"
          echo "  --ip                         Set the IP of external node.(By default is localhost)"1>&2; exit 1; 
}
details(){
	cd /root/back-end
	intface=$(bash mazi-current.sh -i mesh |awk {'print $2'})
	mode=$(jq ."mesh" /etc/mazi/mazi.conf)
	ssid=$(iwconfig $intface | grep ESSID | awk {'print $4'} | sed -e s/ESSID://)	
	echo "mode $mode"
	echo "mesh_ssid $ssid"
	exit 0
}

register_node(){
  ip=$(ifconfig br0 | grep 'inet' | awk '{printf $2}'| grep -o '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*')
  ssd=$(bash /root/back-end/mazi-current.sh -s |awk {'print $NF'})
  data='{"deployment":'$(jq ".deployment" $conf)',
         "ssid":"'$ssd'",
         "admin":'$(jq ".admin" $conf)',
         "title":'$(jq ".title" $conf)',
         "description":'$(jq ".description" $conf)',
         "loc":'$(jq ".loc" $conf)'}'
  node_id=$(curl -s -X POST --data "$data" http://$gateway:$port/register/node/information)
  if [ ! $node_id ];then
     curl -s -X POST  http://$gateway:$port/create/mesh
     node_id=$(curl -s -X POST --data "$data" http://$gateway:$port/register/node/information)
  fi
  curl -s -P POST -d '{"node_id":"'$node_id'","ip":"'$ip'"}' http://$gateway:$port/register/node
  sshKey=$(curl -s -P GET http://$gateway:$port/sshKey)
  echo "$sshKey" >> /root/.ssh/authorized_keys  
}

gateway(){
 cd /root/back-end
 [ $(jq ".mesh" $conf) = '"gateway"' ] && exit 0;
 [ "$wifi_intface" = "$iface" ] && echo "This interface is being used by the Access Point" && exit 0;
 [ "$internet_intface" = "$iface" ] && bash mazi-antenna.sh -d -i $iface
 ifconfig $iface down
 iwconfig $iface mode ad-hoc essid $ssid channel 1
 batctl if add $iface
 ifconfig $iface up
 ifconfig bat0 up
 ifconfig bat0 192.168.1.1/24
 ### configure /etc/hosts ####
 domain=$(bash mazi-current.sh -d | awk '{print $NF}')
 echo "192.168.1.1     $domain" >> /etc/hosts
 echo "192.168.1.1     local.mazizone.eu"  >> /etc/hosts
 ### configure dnsmasq for mesh interface ####
 echo "interface=bat0" >> /etc/dnsmasq.conf
 echo "dhcp-range=bat0,192.168.1.10,192.168.1.200,255.255.255.0,12h" >> /etc/dnsmasq.conf
 service dnsmasq restart
 echo $(cat $conf | jq '.+ {"mesh": "gateway"}') | sudo tee $conf
 curl -s -X POST  http://localhost:$port/create/mesh

}

node(){
  cd /root/back-end
  ifconfig $iface up
  if [ -z "$(iwlist $iface scan | grep -w '.*"'$ssid'"' )" ];then
   echo "Bad mesh signal"
   exit 0;
  fi  
  [ "$wifi_intface" = "$iface" ] && echo "This interface is being used by the Access Point" && exit 0;
  [ "$internet_intface" = "$iface" ] && bash mazi-antenna.sh -d -i $iface
  service mazi-portal stop
  service dnsmasq stop
  ifconfig $iface down
  iwconfig $iface mode ad-hoc essid $ssid channel 1
  ifconfig $iface up
  batctl if add $iface
  ifconfig $iface up
  ifconfig bat0 up

  ip link add name br0 type bridge
  mac=$(ifconfig br0 | grep ether | awk '{print $2}')
  ip link set dev $wifi_intface master br0
  ip link set dev bat0 master br0
  ifconfig br0 hw ether $mac
  ip link set up dev $wifi_intface
  ip link set up dev bat0
  ip link set up dev br0

  sudo dhclient br0
  register_node 
  echo $(cat $conf | jq '.+ {"mesh": "node"}') | sudo tee $conf
}

portal(){
 cd /root/back-end
 iface=$(batctl if | awk '{print $1}'| tr -d :)
 if [ $(jq ".mesh" $conf) = '"node"' ];then
    ifconfig br0 down
    ip link delete br0
    ifconfig bat0 down
    ifconfig $iface down
    batctl if del $iface
    sudo service mazi-portal restart
    sudo service dnsmasq restart
    ip addr flush dev $iface
    iwconfig $iface  essid off mode managed
    killall dhclient
    bash mazi-wifi.sh restart
    echo $(cat $conf | jq '.+ {"mesh": "portal"}') | sudo tee $conf
  elif [ $(jq ".mesh" $conf) = '"gateway"' ];then
    ifconfig bat0 down
    ifconfig $iface down
    batctl if del $iface
    ip addr flush dev $iface
    iwconfig $iface  essid off mode managed
    ## remove mesh configutarion from /etc/hosts ##
    sudo sed -i '/192.168.1.1/d' /etc/hosts
    ## remove mesh configuration from dnsmaq.conf ##
    sudo sed -i '/interface=bat0/d' /etc/dnsmasq.conf
    sudo sed -i '/dhcp-range=bat0,192.168.1.10,192.168.1.200,255.255.255.0,12h/d' /etc/dnsmasq.conf
    sudo service dnsmasq restart 
    bash mazi-wifi.sh restart
    echo $(cat $conf | jq '.+ {"mesh": "portal"}') | sudo tee $conf
  fi
  echo "" > /root/.ssh/authorized_keys
  exit 0;
}

case $1 in
     -d|--details)
     details
     shift
     ;;	
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
     key="$2"
     if [ "$key" == "--ip" ]; then  
	curl -s -P POST -d '{"ip":"'$3'"}' http://localhost:$port/flush/node
        sudo sshpass ssh -o StrictHostKeyChecking=no root@$3 'bash /root/back-end/mazi-mesh.sh portal' &>/dev/null &
     else
        portal
     fi
     ;;
     scan)
     list=$(iwlist $2 scan | grep  -B 3 -A 1 'Mode:Ad-Hoc' | grep ESSID |sed -e s/ESSID:// | tr -d \")     
     echo $list
     ;;
     *)
     usage
     ;;
esac


#set +x




