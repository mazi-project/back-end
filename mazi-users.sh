#!/bin/bash
#set -x
if [[ $2 == "AP-STA-CONNECTED" ]];then
 	name=""
    ip=""
    stoptime=$(( $(date +%s)  + 15 ))
	while [[ -z "$name" ]] && [[ -z $ip ]]; do 
        ip=$(cat /var/lib/misc/dnsmasq.leases | grep $3 | awk {'print $3'})
		name=$(cat /var/lib/misc/dnsmasq.leases | grep $3 | awk {'print $4'})
		if [[ $(date +%s) -ge $stoptime ]];then
			break
		fi
	done
    if [[ -n "$name" ]] && [[ -n $ip ]]; then
		sed -i "/$3/d" /etc/mazi/users.log
		echo "$3 $ip $name" >> /etc/mazi/users.log
	fi
fi
if [[ $2 == "AP-STA-DISCONNECTED" ]];then
	sed -i "/$3/d" /etc/mazi/users.log
fi
#set +x
