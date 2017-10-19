#!/bin/bash

#This script manages all available  sensors 
#
# Usage: sudo sh mazi-sense.sh [senseName] [options]

usage() { echo "Usage: sudo sh mazi-sense.sh [SenseName] [Options] [SensorOptions]"
	  echo ""
	  echo "[SenseName]"
	  echo "  -n,--name                         Set the name of the sensor"
	  echo "                                        {sht11,sensehat....}"
          echo ""
	  echo "[Options]"
          echo "  -s , --store                       Store the measurements in the Database"
          echo "  -d , --duration                    Duration in seconds to take a measurement"
          echo "  -i , --interval                    Seconds between periodic measurement"
          echo "  -a , --available                   Displays the status of the available sensors"
          echo "  -D , --domain                      Set a remote server domain.( Default is localhost )"
          echo ""
	  echo "[SensorOptions]"
	  echo "  {sht11}"
  	  echo "  -t , --temperature                 Get the Temperature "
	  echo "  -h , --humidity                    Get the Humidity" 
          echo ""
          echo "  {sensehat}"
          echo "  -t , --temperature                 Get the Temperature "
          echo "  -h , --humidity                    Get the Humidity" 1>&2; exit 1; }

##### Initialization  ######
DUR="0"     #initialization of duration 
interval="0"     #initialization of interval 
domain="localhost"
conf="/etc/mazi/mazi.conf"
path_sense="/root/back-end/lib"
IP="$(ifconfig wlan0 | grep 'inet addr' | awk '{printf $2}'| grep -o '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*')"

while [ $# -gt 0 ]
do
   key="$1"

   case $key in
        -n|--name)
        NAME="$2"
        shift
        ;;
        -s|--store)
        STORE="true"
        ;;
        -t|--temperature)
        TEMP="$1"
        ;;
        -h|--humidity)
        HUM="$1"
        ;;
        -d|--duration)
        DUR="$2"
        shift
        ;;
        -i|--interval)
        interval="$2"
        shift
        ;;
        -a|--available)
        SCAN="$1"
	;;
        -D|--domain)
        domain="$2"
        shift
        ;;
        *)
        # unknown option
        usage
        ;;
   esac
   shift     #past argument or value
done

##### Scan for available sensors  ######
if [ $SCAN ];then
   if [ -f "/proc/device-tree/hat/product" ]; then
      SERVICE="$(ps -ef | grep sensehat | grep -v 'grep')"
      if [ "$SERVICE" != "" ]; then
         echo "sensehat active $IP"
      else
         echo "sensehat inactive $IP" 
      fi
   fi
   exit 0;
fi

#### Check the sensor name ####
if [ $NAME ];then
   if [ $NAME != "sensehat" -a $NAME != "sht11" ];then
     echo "Invalid sensor name"
     echo ""
     usage 
     exit 0;
   fi
else
    echo "Please complete the sensor name"
    echo ""
    usage 
    exit 0;
fi

##### Register the ID of sensor #####
if [ $STORE ]; then
   #### Take the ID of sensor ####
   ID=$(curl -s -X GET --data '{"deployment":'$(jq ".deployment" $conf)',"sensor_name":"'$NAME'","ip":"'$IP'"}' http://$domain:4567/sensors/id) 

   if [ ! $ID ];then
      device_id=$(curl -s -X GET -d @$conf http://$domain:4567/device/id)
      [ ! $device_id ] && device_id=$(curl -s -X POST -d @$conf http://$domain:4567/deployment/register)
      ID=$(curl -s -X POST --data '{"deployment":'$(jq ".deployment" $conf)',"sensor_name":"'$NAME'","ip":"'$IP'","device_id":"'$device_id'"}' http://$domain:4567/sensor/register)
   fi
   curl -s -X POST --data '{"deployment":'$(jq ".deployment" $conf)'}' http://$domain:4567/create/$NAME
fi

endTime=$(( $(date +%s) + $DUR )) # Calculate end time.
case $NAME in
   sensehat)

   while [ true ]; do
     echo "$NAME"
     temp="$(python $path_sense/$NAME.py $TEMP)"
     hum="$(python $path_sense/$NAME.py $HUM)"
     [ $TEMP ] && echo "The Temperature is: $temp"
     [ $HUM ] &&  echo "The Humidity is: $hum"
     ##### STORE OPTION #####
     if [ $STORE ]; then
        TIME=$(date  "+%H%M%S%d%m%y")
        curl -X POST --data '{"deployment":'$(jq ".deployment" $conf)',"sensor_id":'$ID',"value":{"temp":'$temp',"hum":'$hum'},"date":'$TIME'}' http://$domain:4567/update/$NAME
     fi
     sleep $interval
     [ $(date +%s) -ge $endTime ] && exit 0; 
   done
   ;;
   sht11)

   while [ true ]; do
     echo "$NAME"
     temp="$(python $path_sense/$NAME.py $TEMP)"
     hum="$(python $path_sense/$NAME.py $HUM)"
     [ $TEMP ] && echo "The Temperature is: $temp"
     [ $HUM ] && echo "The Humidity is: $hum"
     ##### STORE OPTION #####
     if [ $STORE ]; then
        TIME=$(date  "+%H%M%S%d%m%y")
        curl -X POST --data '{"deployment":'$(jq ".deployment" $conf)',"sensor_id":'$ID',"value":{"temp":'$temp',"hum":'$hum'},"date":'$TIME'}' http://$domain:4567/update/$NAME
     fi
     sleep $interval
     [ $(date +%s) -ge $endTime ] && exit 0; 
   done
   ;;
   *)

   echo "Wrong name of sensor"
   echo ""
   usage
   ;;
esac
