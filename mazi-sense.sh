#!/bin/bash

#This script manages all available  sensors 
#
# Usage: sudo sh mazi-sense.sh [senseName] [options]
set  -x
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
          echo "  --status                           Displays the status of store process"
          echo ""
	  echo "[SensorOptions]"
	  echo "  {sht11}"
  	  echo "  -t , --temperature                 Get the Temperature "
	  echo "  -h , --humidity                    Get the Humidity" 
          echo "  -p , --pressure                    Get the current pressure in Millibars."
          echo "  -m , --magnetometer                Get the direction of North"
          echo "  -g , --gyroscope                   Get a dictionary object indexed by the strings x, y and z." 
          echo "                                     The values are Floats representing the angle of the axis in degrees"
          echo "  -ac , --accelerometer               Get a dictionary object indexed by the strings x, y and z."
          echo "                                     The values are Floats representing the acceleration intensity of the axis in Gs"
          echo ""
          echo "  {sensehat}"
          echo "  -t , --temperature                 Get the Temperature "
          echo "  -h , --humidity                    Get the Humidity" 1>&2; exit 1; }



status_call() {
  if [ -f /etc/mazi/rest.log ];then
    response=$(tac /etc/mazi/rest.log| grep "$1" | awk -v FS="($1:|http_code:)" '{print $2}')
    http_code=$(tac /etc/mazi/rest.log| grep "$1" | head -1 | awk '{print $NF}')
  fi
  [ "$http_code" = "200" -a "$response" = " OK " ] && call_st="OK" && error=""
  [ "$http_code" = "000" ] && call_st="ERROR:" && error="Connection refused"
  [ "$http_code" = "200" -a "$response" != " OK " ] && call_st="ERROR:" && error="$response"
  [ "$http_code" = "500" ] && call_st="ERROR:" && error="The server encountered an unexpected condition which prevented it from fulfilling the request"

}

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
        -p|--pressure)
        PRE="$1"
        ;;
        -m|--magnetometer)
        MAG="$1"
        ;;
        -g|--gyroscope)
        GYR="$1"
        ;;
        -ac|--accelerometer)
        ACC="$1"
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
        --status)
        status="TRUE"
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

if [ $status ];then
  status_call sensehat
  [ "$(ps aux | grep "store\|\-s" | grep "mazi-sense.sh" | grep "\-n sensehat "| grep -v 'grep')" ] && echo "sensehat active $call_st $error" || echo "sensehat inactive"
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
   ID=$(curl -s -H 'Content-Type: application/json' -X GET --data "{\"deployment\":$(jq ".deployment" $conf),\"sensor_name\":\"$NAME\",\"ip\":\"$IP\"}" http://$domain:4567/sensors/id)

   if [ ! $ID ];then
      device_id=$(curl -s -X GET -d @$conf http://$domain:4567/device/id)
      [ ! $device_id ] && device_id=$(curl -s -X POST -d @$conf http://$domain:4567/monitoring/register)
      ID=$(curl -s -H 'Content-Type: application/json' -X POST --data "{\"deployment\":$(jq ".deployment" $conf),\"sensor_name\":\"$NAME\",\"ip\":\"$IP\",\"device_id\":\"$device_id\"}" http://$domain:4567/sensor/register)
   fi
   curl -s -H 'Content-Type: application/json' -X POST --data "{\"deployment\":$(jq ".deployment" $conf)}" http://$domain:4567/create/measurements
fi

endTime=$(( $(date +%s) + $DUR )) # Calculate end time.
case $NAME in
   sensehat)
   [ ! -f /etc/mazi/rest.log -o ! "$(grep -R "sensehat:" /etc/mazi/rest.log)" ] && echo "sensehat:" >> /etc/mazi/rest.log

   while [ true ]; do
     echo "$NAME"
     [ $TEMP ] && temp="$(python $path_sense/$NAME.py $TEMP)" && echo "The Temperature is: $temp"
     [ $HUM ] && hum="$(python $path_sense/$NAME.py $HUM)" &&  echo "The Humidity is: $hum"
     [ $PRE ] && pressure="$(python $path_sense/$NAME.py $PRE)" && echo  "The pressure is: $pressure Millibars."
  #   [ $MAG ] &&  magneto="$(python $path_sense/$NAME.py $MAG)" && echo  "direction: $magneto"
  #   [ $GYR ] && gyroscope="$(python $path_sense/$NAME.py $GYR)" && echo  "$gyroscope"
  #   [ $ACC ] && accelero="$(python $path_sense/$NAME.py $ACC)" && echo  "$accelero"
     [ "$MAG" -o "$GYR" = "-g" -o "$ACC" ] && python $path_sense/$NAME".py" $GYR $MAG $ACC
     ##### STORE OPTION #####
     if [ $STORE ]; then
        TIME=$(date  "+%H%M%S%d%m%y")
         response=$(curl -s -H 'Content-Type: application/json' -w %{http_code} -X POST --data "{\"deployment\":$(jq ".deployment" $conf),\"sensor_id\":\"$ID\",\"value\":{\"temp\":\"$temp\",\"hum\":\"$hum\"},\"date\":\"$TIME\"}" http://$domain:4567/update/measurements)
         http_code=$(echo $response | tail -c 4)
         body=$(echo $response| rev | cut -c 4- | rev )
         sed -i "/sensehat/c\sensehat: $body $domain http_code: $http_code" /etc/mazi/rest.log

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
        curl -s -H 'Content-Type: application/json'  -X POST --data "{\"deployment\":$(jq ".deployment" $conf),\"sensor_id\":\"$ID\",\"value\":{\"temp\":\"$temp\",\"hum\":\"$hum\"},\"date\":\"$TIME\"}" http://$domain:4567/update/measurements
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

set +x



