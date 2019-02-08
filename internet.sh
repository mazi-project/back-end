#!/bin/bash
#The mazi-internet.sh script is able to modify the mode of your Wi-Fi Access Point – currently - between offline and online
#as the managed mode has not been implemented yet. In the offline mode, clients of the Wi-Fi Access Point have not access
#to the Internet and are permanently redirected to the Portal splash page. In the online mode, the Raspberry Pi provides 
#Internet access through either the Ethernet cable or an external USB Wi-Fi adapter.
## initialization ##
#set -x
cd /root/nodogsplash/
conf="/etc/mazi/mazi.conf"
nodog_path="/etc/nodogsplash/nodogsplash.conf"
domain=$(bash /root/back-end/mazi-current.sh -d | awk {'print $NF'})

usage() { 
         echo "sudo sh mazi-internet.sh [options]" 
         echo ""
         echo "[options]"
         echo "-m,--mode  [offline/online/managed]        Sets the mode of the Wi-Fi Access Point" 1>&2; exit 1; 
}
offline(){
  sudo sed -i '/address=\/#\/10.0.0.1/d' /etc/dnsmasq.conf
  sudo sed -i '/#Redirect rule/a \address=\/#\/10.0.0.1' /etc/dnsmasq.conf
  sudo service dnsmasq restart  
  #Save rules.v4 rules
 # sudo iptables-save | sudo tee /etc/iptables/rules.v4
  echo You are now in offline mode
  echo $(cat $conf | jq '.+ {"mode": "offline"}') | sudo tee $conf
  #restart nodogsplash
  /etc/init.d/nodogsplash stop 
  sleep 1
  /etc/init.d/nodogsplash start 
}

online(){
  #Save rules.v4 rules
 # sudo iptables-save | sudo tee /etc/iptables/rules.v4
  echo You are now in online mode
  echo $(cat $conf | jq '.+ {"mode": "online"}') | sudo tee $conf
  sudo sed -i '/address=\/#\/10.0.0.1/d' /etc/dnsmasq.conf
  sudo service dnsmasq restart
  #restart nodogsplash
  /etc/init.d/nodogsplash stop
  sleep 1
  /etc/init.d/nodogsplash start
}
limit(){
if [ $1 = "flush" ];then
  sudo ndsctl stop &>/dev/null
  sudo sed -i '/DownloadLimit/d' /etc/nodogsplash/nodogsplash.conf
  sudo sed -i '/TrafficControl yes/d' /etc/nodogsplash/nodogsplash.conf
  sudo /root/nodogsplash/nodogsplash &>/dev/null	
else
  sudo ndsctl stop &>/dev/null
  sudo sed -i '/DownloadLimit/d' /etc/nodogsplash/nodogsplash.conf
  echo "DownloadLimit $1" >> /etc/nodogsplash/nodogsplash.conf
  echo "TrafficControl yes" >> /etc/nodogsplash/nodogsplash.conf
  sudo /root/nodogsplash/nodogsplash &>/dev/null	
fi
}

auth(){
	mac=$(cat /etc/mazi/users.log | grep $1 | awk {'print $1'})
	datE=$(date +"%Y-%m-%d %T")
	sudo sed -i "/$mac/d" /etc/mazi/users.dat
	echo "$mac $datE" >> /etc/mazi/users.dat
	ndsctl auth $mac
    ndsctl trust $mac
}

deauth(){
	mac=$(cat /etc/mazi/users.log | grep $1 | awk {'print $1'})
	sudo sed -i "/$mac/d" /etc/mazi/users.dat
	ndsctl deauth $mac
    ndsctl untrust $mac
}

restricted(){
  echo You are now in restricted mode
  echo $(cat $conf | jq '.+ {"mode": "online"}') | sudo tee $conf
  sudo sed -i '/address=\/#\/10.0.0.1/d' /etc/dnsmasq.conf
  sudo service dnsmasq restart
  /etc/init.d/nodogsplash stop
  sleep 1
  /etc/init.d/nodogsplash start
  echo $(cat $conf | jq '.+ {"mode": "restricted"}') | sudo tee $conf
}

while [ $# -gt 0 ]
do
key="$1"

case $key in
   -m|--mode)
    [ "$2" = "offline" ] && offline
    [ "$2" = "online" ] && online
    [ "$2" = "restricted" ] && restricted 
    shift 
    ;;
    -l|--limit)
    limit $2
    shift
    ;;
    -d|--deauth)
    deauth $2
    shift
    ;;
    -a|--auth)
    auth $2
    shift
    ;;    
    *)
    usage
    ;;
    esac
    shift
done

#set +x
