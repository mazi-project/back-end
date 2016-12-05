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

				# Block Internet
				sudo iptables -A FORWARD -i wlan1 -j DROP
				sudo iptables -A FORWARD -i eth0 -j DROP

				# Redirect to apache
				sudo iptables -t nat -A PREROUTING -p tcp -m tcp --dport 80 -j DNAT --to-destination 10.0.0.1

				#Save rules.v4 rules
				sudo iptables-save | sudo tee /etc/iptables/rules.v4
				
				echo You are now in offline mode 

			elif [ "$MODE" = "dual" ]; then
				#echo $MODE 

				#Delete iptables rules
				sudo iptables -F
				sudo iptables -F -t nat

				# Forward Internet through eth0
				sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
				# Forward Internet through wlan0
				sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE

				echo You are now in dual mode 

			elif [ "$MODE" = "restricted" ]; then
				echo $MODE
			else
				echo "Please choose between offline, dual or restricted mode"
			fi
		;;
		*)
			usage
			;;
        esac
done


