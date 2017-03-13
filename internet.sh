#!/bin/bash

usage() { echo "Usage: sh $0 [-m <offline/dual/restricted>]" 1>&2; exit 1; }

while getopts m: option
do
        case "${option}"
        in
                m) MODE=${OPTARG}
			if [ "$MODE" = "offline" ]; then
				#echo $MODE

				#Delete iptables rules
				sudo iptables -F
				sudo iptables -F -t nat
				sudo iptables -F -t mangle				
		
				# Block Internet
				sudo iptables -A FORWARD -i wlan1 -j DROP
				sudo iptables -A FORWARD -i eth0 -j DROP

				# Redirect HTTP to apache
				sudo iptables -t mangle -N HTTP
				sudo iptables -t mangle -A PREROUTING -i wlan0 -p tcp -m tcp --dport 80 -j HTTP
				sudo iptables -t mangle -A HTTP -j MARK --set-mark 99
				sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp -m mark --mark 99 -m tcp --dport 80 -j DNAT --to-destination 10.0.0.1
		
				# Redirect HTTPS to apache
				sudo iptables -t mangle -N HTTPS
				sudo iptables -t mangle -A PREROUTING -i wlan0 -p tcp -m tcp --dport 443 -j HTTPS
				sudo iptables -t mangle -A HTTPS -j MARK --set-mark 98
				sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp -m mark --mark 98 -m tcp --dport 443 -j DNAT --to-destination 10.0.0.1


				#Save rules.v4 rules
				sudo iptables-save | sudo tee /etc/iptables/rules.v4
				
				echo You are now in offline mode 
                                echo 'offline' | sudo tee /etc/mazi/mazi.conf

			elif [ "$MODE" = "dual" ]; then
				#echo $MODE 

				#Delete iptables rules
				sudo iptables -F
				sudo iptables -F -t nat
				sudo iptables -F -t mangle

				# Forward Internet through eth0
				sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
				# Forward Internet through wlan0
				sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
                               
                                #Save rules.v4 rules
                                sudo iptables-save | sudo tee /etc/iptables/rules.v4
				
                                echo You are now in dual mode
                                echo 'dual' | sudo tee /etc/mazi/mazi.conf 

			elif [ "$MODE" = "restricted" ]; then
				echo $MODE
                                echo 'restricted' | sudo tee /etc/mazi/mazi.conf
			else
				echo "Please choose between offline, dual or restricted mode"
			fi
		;;
		*)
			usage
			;;
        esac
done


