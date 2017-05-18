#!/bin/bash

#This script manages all available  sensors 
#
# Usage: sudo sh mazi-sense.sh [senseName] [options]
# 
#
# [senseName]
# -n,--name                       Set the name of the sensor
#
# [options]
# -s , --store                    Store the measurements to Database through the restAPI
# -d , --duration                 Duration in seconds to take a measurement
# -i , --interval                 Seconds between periodic measurement                               
#
#
# [sth11]
# -t , --temporature              Displays the Temporature 
# -h , --humidity                 Displays the Humidity 
#set -x
#


usage() { echo "Usage: sudo sh mazi-sense.sh [SenseName] [Options] [SensorOptions]"
	  echo ""
	  echo "[SenseName]"
	  echo "-n,--name  [sth11,..]              Set the name of the sensor"
	  echo ""
	  echo "[Options]"
          echo "-s , --store                       Store the measurements in the Database"
          echo "-d , --duration                    Duration in seconds to take a measurement"
          echo "-i , --interval                    Seconds between periodic measurement"
          echo ""
	  echo "[SensorOptions]"
	  echo "[sth11]"
  	  echo "-t , --temperature                  Get the Temperature "
	  echo "-h , --humidity                     Get the Humidity" 1>&2; exit 1; }
DUR="0"
INT="0"
path_sense="$(pwd)/lib"
path_type="/etc/mazi"
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
        INT="$2"
        shift
        ;;
        *)
        # unknown option
        usage
        ;;
   esac
   shift     #past argument or value
done

#### Create the file Type #####
if [ ! -f "$path_type/Type" ]; then
    sudo touch $path_type/Type
fi

#### Check the sensor name ####
   if [ ! $NAME ];then
      echo "Please complete the SenseName"
      echo ""
      usage 
      exit 0;
   fi

endTime=$(( $(date +%s) + $DUR )) # Calculate end time.

while [ true ]; do

   ##### STH11 Sensor #####
   if [ "$NAME" = "sth11"  ];then
      echo "$NAME"
      temp="$(python $path_sense/sth11.py $TEMP)"
      hum="$(python $path_sense/sth11.py $HUM)"
      if [ $TEMP ]; then
         echo "The Temperature is: $temp"
      fi
      if [ $HUM ]; then
         echo "The Humidity is: $hum"
      fi
      ##### STORE OPTION #####
      if [ $STORE ]; then
         #### Take the ID of sensor ####
         ID=$(cat $path_type/Type | grep "$NAME" | awk '{print $2}')   #Search for id that corresponds to the name of the sensor
         if [ ! $ID ]; then                                   #If ID doesn't exist, get the ID through the restAPI
            ID=$(curl -s -X POST  http://portal.mazizone.eu/sensors/register/$NAME)
            sudo echo "$NAME  $ID" >> $path_type/Type
         fi
         TIME=$(date  "+%H%M%S%d%m%y")
         curl --data '{"sensor_id":'$ID',"value":{"temp":'$temp',"hum":'$hum'},"date":"'$TIME'"}' http://portal.mazizone.eu/sensors/store
      fi
   fi


   #### Exit Statement ####
   sleep $INT
   if [ $(date +%s) -ge $endTime ]; then
      exit 0  
   fi
done

