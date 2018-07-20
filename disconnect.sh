#!/bin/bash 
set -x
while [ $# -gt 0  ]
do
  key="$1"
  case $key in
    -w|--write)
    #write $2
    sudo echo $2 >> /etc/mazi/users.dat 
    shift
    ;;
    --disconnect)
    disconnect
    ;;
  esac
  shift
done

write(){
 mac=$1
 sudo echo $mac >> /etc/mazi/users.dat
}

disconnetc(){
tail -f -n 1 /var/log/syslog | while read LOGLINE
do
  if [[ "${LOGLINE}" == *"disassociated"* ]];then 
    mac=$(echo $LOGLINE | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
    ndsctl deauth $mac
    sed -i "/$mac/d" /var/www/html/nodog/users.dat
    sed -i '/^$/d' /var/www/html/nodog/users.dat
  fi
done
}
set +x
