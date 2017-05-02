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
# -s , --store                    Store the measurements to Database through restAPI
#
# [STH11]
# -t , --temporature              Displays the Temporature 
# -h , --humidity                 Displays the Humidity 
#set -x

usage() { echo "Usage: sudo sh mazi-sense.sh [SenseName] [Options] [SensorOptions]"
	  echo ""
	  echo "[SenseName]"
	  echo "-n,--name                       Set the name of the sensor"
	  echo ""
	  echo "[Options]"
          echo "-s , --store                    Store the measurements to Database through restAPI"
          echo ""
	  echo "[SensorOptions]"
	  echo "[STH11]"
  	  echo "-t , --temporature              Get the Temporature "
	  echo "-h , --humidity                 Get the Humidity" 1>&2; exit 1; }


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
     TEMP="true"
     ;;
     -h|--humidity)
     HUM="true"
     ;;
     *)
     # unknown option
     usage
     ;;
esac
shift     #past argument or value
done

###### Check the sensor name ######

if [ "$NAME" = "" ];then
   echo "Please complete the SenseName"
   echo ""
   usage 
   exit 0;
fi

##### Take the name of the sensor through a rast API ######

#name="$(curl -s  http://portal.mazizone.eu/sensors/name/$ID)"

##### STH11 Sensor #####

if [ "$NAME" = "sth11" -o "$NAME" = "STH11" ];then
   echo "$NAME"

   ##### GET THE MEASUREMENT #####
   if [ "$TEMP" = "true" ]; then
     TEMP=$(python sth11.py -t)
     echo "$TEMP"
   elif [ "$HUM" = "true" ]; then
     HUM=$(python sth11.py -h)
     echo "$HUM"
   else
     TEMP=$(python sth11.py -t)
     HUM=$(python sth11.py -h)
     echo "$TEMP"
     echo "$HUM"
   fi

   ##### STORE OPTION #####
   if [ "$STORE" = "true" ]; then

     #### check the id of sensore ####
     cd $path
     ID=$(cat type | grep 'sth11' | awk '{print $2}')
     echo $ID
   fi

else

  if [ "$TEMP" = "true" -o "$HUM" = "true" ]; then
      echo "invalid option for sensor $name"
      echo "Try 'sh mazi-sense.sh --help' for more information"
      exit 0;
  fi
fi
#set +x


