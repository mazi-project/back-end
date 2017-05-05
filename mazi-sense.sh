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
# -d , --duration                 The time to run this script.To second
#                                
#
#
# [sth11]
# -t , --temporature              Displays the Temporature 
# -h , --humidity                 Displays the Humidity 
#set -x

usage() { echo "Usage: sudo sh mazi-sense.sh [SenseName] [Options] [SensorOptions]"
	  echo ""
	  echo "[SenseName]"
	  echo "-n,--name  [sth11,..]              Set the name of the sensor"
	  echo ""
	  echo "[Options]"
          echo "-s , --store                       Store the measurements to Database through restAPI"
          echo "-d , --duration                    The time to run this script.To second"
          echo ""
	  echo "[SensorOptions]"
	  echo "[sth11]"
  	  echo "-t , --temporature                  Get the Temporature "
	  echo "-h , --humidity                     Get the Humidity" 1>&2; exit 1; }

DUR="1"
path=$(pwd)
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
     -t|--temporature)
     TEMP="$1"
     ;;
     -h|--humidity)
     HUM="$1"
     ;;
     -d|--duration)
     DUR="$2"
     shift
     ;;
     *)
     # unknown option
     usage
     ;;
esac
shift     #past argument or value
done



endTime=$(( $(date +%s) + $DUR )) # Calculate end time.


while [ $(date +%s) -lt $endTime ]; do 
echo "$(date +%s) => $endTime"
sleep 1
###### Check the sensor name ######

if [ "$NAME" = "" ];then
   echo "Please complete the SenseName"
   echo ""
   usage 
   exit 0;
fi



##### STH11 Sensor #####

if [ "$NAME" = "sth11"  ];then
   echo "$NAME"
   temp="$(python sth11.py $TEMP)"
   hum="$(python sth11.py $HUM)"
   echo "The Temporature is: $temp"
   echo "The Humidity is: $hum"


fi


##### STORE OPTION #####
if [ "$STORE" = "true" ]; then

   #### Take the ID of sensor ####
   cd $path
   if [ -f "Type" ]; then      # Check if a file Type exists
      ID=$(cat Type | grep "$NAME" | awk '{print $2}')   #Search for id that corresponds to the name of the sensor

      if [ "$ID" = "" ]; then                                   #If doesn't exist, get the ID through the restAPI
         ID=$(curl -s -X POST  http://portal.mazizone.eu/sensors/register/$NAME)
         sudo echo "$NAME  $ID" >> $path/Type
      fi
   else                              #If file doesn't exist, create it and get the ID through the restAPI
     sudo touch Type
     ID=$(curl -s -X POST  http://portal.mazizone.eu/sensors/register/$NAME)
     echo "$NAME  $ID" | sudo tee $path/Type
   fi

   #### Call the store method ####
  TIME=$(date  "+%H%M%S%d%m%y")

  curl --data '{"sensor_id":'$ID',"value":{"temp":'$temp',"hum":'$hum'},"date":"'$TIME'"}' http://portal.mazizone.eu/sensors/store
fi

done
#set +x
