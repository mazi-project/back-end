#!/bin/bash
#The mazi-internet.sh script is able to modify the mode of your Wi-Fi Access Point – currently - between offline and dual
#as the managed mode has not been implemented yet. In the offline mode, clients of the Wi-Fi Access Point have not access
#to the Internet and are permanently redirected to the Portal splash page. In the dual mode, the Raspberry Pi provides 
#Internet access through either the Ethernet cable or an external USB Wi-Fi adapter.

usage() { 
         echo "sudo sh mazi-internet.sh [options]" 
         echo ""
         echo "[options]"
         echo "-m,--mode  [offline/dual/managed]        Sets the mode of the Wi-Fi Access Point" 1>&2; exit 1; }


conf="/etc/mazi/mazi.conf"
nodog_path="/etc/nodogsplash/nodogsplash.conf"
while [ $# -gt 0 ]
do
   case "$1" in
   -m|--mode) MODE="$2"
            if [ "$MODE" = "offline" ]; then
	        #echo $MODE
                #interface
		 #sed -i '/FirewallRule .* to 0.0.0.0/c\    FirewallRule drop to 0.0.0.0/0' $nodog_path 
                #redirect url
		sed -i '/FirewallRule .* to 0.0.0.0/c\    FirewallRule drop to 0.0.0.0/0' $nodog_path 

		echo You are now in offline mode
                echo $(cat $conf | jq '.+ {"mode": "offline"}') | sudo tee $conf

	  elif [ "$MODE" = "dual" ]; then
		#echo $MODE

		#Delete redirect from DNSMAQ
                sudo sed -i '/address=\/#\/10.0.0.1/d' /etc/dnsmasq.conf


		#Delete iptables rules
	        sudo iptables -F
		sudo iptables -F -t nat
		sudo iptables -F -t mangle

		# Forward Internet through eth0
		sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
		# Forward Internet through wlan0
		sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
		# Forward Internet through wlan0
		sudo iptables -t nat -A POSTROUTING -o wlan1 -j MASQUERADE

		#Restart DNSMASQ
                sudo service dnsmasq restart
                #Save rules.v4 rules
                sudo iptables-save | sudo tee /etc/iptables/rules.v4

                echo You are now in dual mode
                echo $(cat $conf | jq '.+ {"mode": "dual"}') | sudo tee $conf

	  elif [ "$MODE" = "managed" ]; then
		 echo $MODE
                  echo $(cat $conf | jq '.+ {"mode": "managed"}') | sudo tee $conf
	  else
		echo "Please choose between offline, dual or managed mode"
	  fi
          shift
	  ;;
	  *)
	  usage
	  ;;
        esac
        shift
done


