#!/bin/bash

#This script manages all available  sensors 
#
# Usage: sudo sh mazi-sense.sh [senseName] [options]
#
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
# [sht11]
# -t , --temporature              Displays the Temporature 
# -h , --humidity                 Displays the Humidity 
#
# [sensehat]
# -t , --temporature              Displays the Temporature 
# -h , --humidity                 Displays the Humidity 
#
#set -x
#


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
          echo ""
	  echo "[SensorOptions]"
	  echo "  {sht11}"
  	  echo "  -t , --temperature                 Get the Temperature "
	  echo "  -h , --humidity                    Get the Humidity" 
          echo ""
          echo "  {sensehat}"
          echo "  -t , --temperature                 Get the Temperature "
          echo "  -h , --humidity                    Get the Humidity" 1>&2; exit 1; }

DUR="0"     #initialization of duration 
INT="0"     #initialization of interval 
path_sense="/root/back-end/lib"
path_Type="/etc/mazi"

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
        -a|--available)
        SCAN="$1"
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
         echo "sensehat active"
      else
         echo "sensehat inactive" 
      fi
   fi
   exit 0;
fi

#### Check the sensor name ####
if [ ! $NAME ];then
    echo "Please complete the SenseName"
    echo ""
    usage 
    exit 0;
fi

endTime=$(( $(date +%s) + $DUR )) # Calculate end time.

##### Register the ID of sensor #####
if [ $STORE ]; then
   #### Take the ID of sensor ####
   IP="$(ifconfig wlan0 | grep 'inet addr' | awk '{printf $2}'| grep -o '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*')" 
   ID="$(curl -s -X GET --data '{"name":"'$NAME'","ip":"'$IP'"}' http://10.0.0.1:4567/sensors/id)" #Search for id that corresponds to the name
                                                                                                   # and ip of the sensor
   if [ ! $ID ]; then               #If ID doesn't exist,register the sensor and get the ID  
      ID="$(curl -s -X POST --data '{"name":"'$NAME'","ip":"'$IP'"}' http://10.0.0.1:4567/sensors/register)" 
   fi
fi
 
while [ true ]; do

   ##### SHT11 Sensor #####
   if [ "$NAME" = "sht11"  ];then
      echo "$NAME"
      temp="$(python $path_sense/$NAME.py $TEMP)"
      hum="$(python $path_sense/$NAME.py $HUM)"
      if [ $TEMP ]; then
         echo "The Temperature is: $temp"
      fi
      if [ $HUM ]; then
         echo "The Humidity is: $hum"
      fi
      ##### STORE OPTION #####
      if [ $STORE ]; then
         TIME=$(date  "+%H%M%S%d%m%y")
         curl -X POST --data '{"sensor_id":'$ID',"value":{"temp":'$temp',"hum":'$hum'},"date":'$TIME'}' http://10.0.0.1:4567/sensors/store
      fi
   fi

    ##### SenseHat Sensor #####
   if [ "$NAME" = "sensehat" ];then
      echo "$NAME"
      temp="$(python $path_sense/$NAME.py $TEMP)"
      hum="$(python $path_sense/$NAME.py $HUM)"
      if [ $TEMP ]; then
         echo "The Temperature is: $temp"
      fi
      if [ $HUM ]; then
         echo "The Humidity is: $hum"
      fi
      ##### STORE OPTION #####
      if [ $STORE ]; then
         TIME=$(date  "+%H%M%S%d%m%y")
         curl -X POST --data '{"sensor_id":'$ID',"value":{"temp":'$temp',"hum":'$hum'},"date":'$TIME'}' http://10.0.0.1:4567/sensors/store
      fi
   fi

   #### Exit Statement ####
   sleep $INT
   if [ $(date +%s) -ge $endTime ]; then
      exit 0  
   fi
done

#set +x

