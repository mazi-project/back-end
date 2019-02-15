#!/bin/bash
#set -x
if [[ $2 == "AP-STA-CONNECTED" ]];then
 	name=""
    ip=""
    stoptime=$(( $(date +%s)  + 15 ))
	while [[ -z $ip ]]; do 
        ip=$(arp -n | grep -w -i $3 | awk '{print $1}')
	    sleep 1
		if [[ $(date +%s) -ge $stoptime ]];then break; fi
	done
    stoptime=$(( $(date +%s)  + 15 ))
	while [[ -z "$name" ]] ; do 
		name=$(cat /var/lib/misc/dnsmasq.leases | grep $3 | awk {'print $4'})
	    sleep 1
		if [[ $(date +%s) -ge $stoptime ]];then
		 name=$(nbtscan $ip -e | awk {'print $NF'})
		 if [[ -z $name ]];then name="-";fi
		 break 
		fi
	done
 	if [[ -n $ip ]];then
		sed -i "/$3/d" /etc/mazi/users.log
		echo "$3 $ip $name" >> /etc/mazi/users.log
	fi
fi
if [[ $2 == "AP-STA-DISCONNECTED" ]];then
	sed -i "/$3/d" /etc/mazi/users.log
fi
#set +x
