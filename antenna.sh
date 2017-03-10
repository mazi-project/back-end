#!/bin/bash  

#This script set up the second antenna 
#
# Usage: sudo sh antenna.sh  [options]
# 
# [options]
# -a,--active                     Displays if ACTIVE if we have second antena 
# -s,--ssid                       Set the name of  WIFI network
# -p,--password                   Set the password of WIFI network
#



usage() { echo "Usage: sudo sh antenna.sh  [options]" 
	  echo ""
          echo "[options]"
	  echo " -a,--active                     Displays if ACTIVE if we have second antena" 
          echo " -s,--ssid                       Set the name of  WIFI network"
          echo " -p,--password                   Set the password of WIFI network"1>&2; exit 1; }


while [ $# -gt 0 ]
do
key="$1"

case $key in
    -s|--ssid)
    ssid="$2"
    shift # past argument=value
    ;;
    -p|--password)
    password="$2"
    shift # past argument=value
    ;;
    -a|--active)
    active="TRUE"
    ;;
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
       # unknown option
    usage   
    ;;
esac
shift     #past argument or value
done

intface=$(ifconfig | grep "wlan1" | awk '{print $1}')

if [ "$active" = "TRUE" ];then
      if [ "$intface" ];then
         echo "active"
      else
         echo "inactive"
      fi
      exit 0;
fi


exit 1;
