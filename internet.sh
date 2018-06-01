#!/bin/bash
#The mazi-internet.sh script is able to modify the mode of your Wi-Fi Access Point – currently - between offline and dual
#as the managed mode has not been implemented yet. In the offline mode, clients of the Wi-Fi Access Point have not access
#to the Internet and are permanently redirected to the Portal splash page. In the dual mode, the Raspberry Pi provides 
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
         echo "-m,--mode  [offline/dual/managed]        Sets the mode of the Wi-Fi Access Point" 1>&2; exit 1; 
}
offline(){
  sudo sed -i '/address=\/#\/10.0.0.1/d' /etc/dnsmasq.conf
  sudo sed -i '/#Redirect rule/a \address=\/#\/10.0.0.1' /etc/dnsmasq.conf
  sudo service dnsmasq restart  
  #redirect url
  ndsctl stop
  sed -f /etc/hostapd/replace.sed /etc/nodogsplash/offline.txt > $nodog_path
  sed -i "s/domain/$domain/g" $nodog_path 
  sleep 1
  nodogsplash 2 > /dev/null
  #Save rules.v4 rules
  sudo iptables-save | sudo tee /etc/iptables/rules.v4
  echo You are now in offline mode
  echo $(cat $conf | jq '.+ {"mode": "offline"}') | sudo tee $conf
}

dual(){
  ndsctl stop
  sed -f /etc/hostapd/replace.sed /etc/nodogsplash/online.txt > $nodog_path
  sed -i "s/domain/$domain/g" $nodog_path 
  sleep 1
  nodogsplash 2 > /dev/null
  #Save rules.v4 rules
  sudo iptables-save | sudo tee /etc/iptables/rules.v4
  echo You are now in dual mode
  echo $(cat $conf | jq '.+ {"mode": "dual"}') | sudo tee $conf
  sudo sed -i '/address=\/#\/10.0.0.1/d' /etc/dnsmasq.conf
  sudo service dnsmasq restart
}
managed(){
  cd /root/back-end/
  mode=$(sh mazi-current.sh -m | awk '{print $2}')
  
}



while [ $# -gt 0 ]
do
key="$1"

case $key in
   -m|--mode)
    [ "$2" = "offline" ] && offline
    [ "$2" = "dual" ] && dual
    [ "$2" = "managed" ] && managed $3 && shift
    shift 
    ;;
    *)
    usage
    ;;
    esac
    shift
done


#set +x
