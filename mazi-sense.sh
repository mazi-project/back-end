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
# [sth11]
# -t , --temporature              Displays the Temporature 
# -h , --humidity                 Displays the Humidity 
#set -x

usage() { echo "Usage: sudo sh mazi-sense.sh [SenseName] [Options] [SensorOptions]"
	  echo ""
	  echo "[SenseName]"
	  echo "-n,--name  [sth11,..]            Set the name of the sensor"
	  echo ""
	  echo "[Options]"
          echo "-s , --store                    Store the measurements to Database through restAPI"
          echo ""
	  echo "[SensorOptions]"
	  echo "[sth11]"
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



##### STH11 Sensor #####

if [ "$NAME" = "sth11" ];then
   echo "$NAME"

   ##### GET THE MEASUREMENT #####
   if [ "$TEMP" = "true" ]; then
     VALUE[0]="$(python sth11.py -t)"
     echo "The Temporature is: ${VALUE[0]}"
   elif [ "$HUM" = "true" ]; then
     VALUE[1]="$(python sth11.py -h)"
     echo "The Humidity is: ${VALUE[1]}"
   else
     VALUE[0]="$(python sth11.py -t)"
     VALUE[1]="$(python sth11.py -h)"
     echo "The temporature is: ${VALUE[0]}"
     echo "The Humidity is: ${VALUE[1]}"
   fi

   echo "${VALUE[*]}"

else

  if [ "$TEMP" = "true" -o "$HUM" = "true" ]; then
      echo "invalid option for sensor $name"
      echo "Try 'sh mazi-sense.sh --help' for more information"
      exit 0;
  fi
fi


##### STORE OPTION #####
if [ "$STORE" = "true" ]; then

   #### Take the ID of sensor ####
   cd $path
   if [ -f "Type" ]; then      # Check if a file Type exists
      ID=$(cat Type | grep "$NAME" | awk '{print $2}')   #Search for id that corresponds to the name of the sensor

      if [ "$ID" = "" ]; then                                   #If doesn't exist, get the ID through the restAPI
         ID=$(curl -s -X POST  http://portal.mazizone.eu/sensors/type/id/$NAME)
         sudo echo "$NAME  $ID" >> $path/Type
      fi
   else                              #If file doesn't exist, create it and get the ID through the restAPI
     sudo touch Type
     ID=$(curl -s -X POST  http://portal.mazizone.eu/sensors/type/id/$NAME)
     echo "$NAME  $ID" |sudo tee $path/Type
   fi

   #### Call the store method ####
   TIME=$(date)
   curl --data "time=$TIME&value=${VALUE[*]}&sensor_id=$ID" http://portal.mazizone.eu/sensors
fi




#set +x



