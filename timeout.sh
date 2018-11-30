#!/bin/bash 
filename="/etc/mazi/users.dat"
nodogMinutes=$(cat /etc/nodogsplash/nodogsplash.conf | grep "AuthIdleTimeout" | awk {'print $NF'})
while true; 
do
  while read -r line
  do
    current=$(echo $line | awk '{$1="";print $0}') 
    mac=$(echo $line | awk '{print $1}')
    CURRENT=$(date +%s -d "$current")
    target=$(date "+%F %T %z")
    TARGET=$(date +%s -d "$target")
    MINUTES=$(( ($TARGET - $CURRENT) / 60 ))

    if [ $MINUTES -ge $nodogMinutes ];then 
      sed -i "/$line/d" $filename
      ndsctl deauth $mac >/dev/null
      ndsctl untrust $mac >/dev/null
    fi
    done < "$filename"
    sleep 60;
done
