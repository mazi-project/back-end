#!/bin/bash

#The mazi-sense.sh has been created in order to manage various sensors connected to the Raspberry Pi.
#This script can detect the connected sensor devices and consequently collect measurements  periodically with 
#a specific duration and interval between measurements. In addition, it can store these measurements in a local
#or remote database and check the status of the storage procedure, as well.
#set -x
##### Initialization  ######
cd /root/back-end
DUR="0"     #initialization of duration
interval="0"     #initialization of interval
domain="localhost"
conf="/etc/mazi/mazi.conf"
path_sense="/root/back-end/lib"
IP="$(ifconfig wlan0 | grep 'inet addr' | awk '{printf $2}'| grep -o '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*')"
i=0
port="7654"

#### Functions ####
usage() { echo "Usage: sudo sh mazi-sense.sh [SenseName] [Options] [SensorOptions]"
	  echo ""
	  echo "[SenseName]"
	  echo "  -n,--name                         The name of the sensor"
          echo ""
	  echo "[Options]"
          echo "  -s , --store                       Stores the measurements in the database"
          echo "  -d , --duration                    Duration in seconds to take a measurements"
          echo "  -i , --interval                    Seconds between periodic measurements"
          echo "  -a , --available                   Displays the status of the available sensors"
          echo "  -D , --domain                      Sets a remote server domain (default is localhost)"
          echo "  --status                           Displays the status of store process"
          echo ""
	  echo "[SensorOptions]"
          read -a sensors <<<$(find lib/ -maxdepth 1 -name "*.py")
          for s in ${sensors[@]}
          do
             python $s --help
          done                     1>&2; exit 1; }



status_call() {
  if [ -f /etc/mazi/rest.log ];then
    response=$(tac /etc/mazi/rest.log| grep "$1" | awk -v FS="($1:|http_code:)" '{print $2}')
    http_code=$(tac /etc/mazi/rest.log| grep "$1" | head -1 | awk '{print $NF}')
  fi
  [ "$http_code" = "200" -a "$(echo $response | grep "OK")" ] && call_st="OK" && error=""
  [ "$http_code" = "000" ] && call_st="ERROR:" && error="Connection refused"
  [ "$http_code" = "200" -a ! "$(echo $response | grep "OK")" ] && call_st="ERROR:" && error="$response"
  [ "$http_code" = "500" ] && call_st="ERROR:" && error="The server encountered an unexpected condition which prevented it from fulfilling the request"
}

make_data(){
 
 TIME=$(date  "+%Y-%m-%d %H:%M:%S")
 read -a values <<<$(python lib/$NAME.py ${argum[@]})
 data='{'$(echo $(printf "\"%s\":\"%s\", "  "${values[@]}"))'
        "time":"'$TIME'",
        "sensor_id":"'$ID'"}'

 echo "$NAME"
 echo ${values[@]}
}

sensor_id(){
 ##### Sensors types ###########
 read -a senstypes <<<$(python lib/$NAME.py ${argum[@]} | awk '{print $1}')
 senstypes="$(printf '%s\n' "${senstypes[@]}" | jq -R . | jq -s .)"

 device_id=$(curl -s -X GET -d @$conf http://$domain:$port/device/id)
 ID=$(curl -s -H 'Content-Type: application/json' -X GET --data "{\"deployment\":$(jq ".deployment" $conf),\"sensor_name\":\"$NAME\",\"ip\":\"$IP\",\"device_id\":\"$device_id\"}" http://$domain:$port/sensors/id)

 ### Create the table measurements or update it with new types of sensors
 curl -s -H "Content-Type: application/json" -H 'Accept: application/json' -X POST -d "{\"senstypes\":$senstypes}" http://$domain:$port/create/measurements > /dev/null
}

register_sensors(){
 read -a sensors <<<$(find lib/ -maxdepth 1 -name "*.py" -exec basename \{} .py \;)
 for name in ${sensors[@]};do
   var=$(python lib/$name.py --detect 2>&1)
   if [ "$var" == "$name" ];then
      device_id=$(curl -s -X GET -d @$conf http://$domain:$port/device/id)
      [ ! $device_id ] && device_id=$(curl -s -X POST -d @$conf http://$domain:$port/monitoring/register)

      ID=$(curl -s -H 'Content-Type: application/json' -X GET --data "{\"deployment\":$(jq ".deployment" $conf),\"sensor_name\":\"$name\",\"ip\":\"$IP\",\"device_id\":\"$device_id\"}" http://$domain:$port/sensors/id)
      ### Register the sensor ####
      [ ! $ID ] && curl -s -H 'Content-Type: application/json' -X POST --data "{\"deployment\":$(jq ".deployment" $conf),\"sensor_name\":\"$name\",\"ip\":\"$IP\",\"device_id\":\"$device_id\"}" http://$domain:$port/sensor/register > /dev/null
   fi
 done
}

available_fun(){
 read -a sensors <<<$(find lib/ -maxdepth 1 -name "*.py" -exec basename \{} .py \;)
 for name in ${sensors[@]}
 do
    var=$(python lib/$name.py --detect 2>&1)
    if [ "$var" == "$name" ];then
       ID=$(curl -s -H 'Content-Type: application/json' -X GET --data "{\"deployment\":$(jq ".deployment" $conf),\"sensor_name\":\"$name\",\"ip\":\"$IP\",\"device_id\":\"$device_id\"}" http://$domain:$port/sensors/id)
       SERVICE="$(ps -ef | grep $name | grep -v 'grep'| grep -v '\-m\|\-ac\|\-g')"
       [ "$SERVICE" != "" ] && echo "$name active $IP $ID" || echo "$name inactive $IP $ID"
    fi
 done
 exit 0;
}


status_fun(){
  read -a sensors <<<$(find lib/ -maxdepth 1 -name "*.py" -exec basename \{} .py \;)
  for name in ${sensors[@]}
  do
    status_call $name
    [ "$(ps aux | grep "store\|\-s" | grep "mazi-sense.sh" | grep "\-n $name "| grep -v 'grep'| grep -v '\-m\|\-ac\|\-g')" ] && echo "$name active $call_st $error" || echo "$name inactive"
  done
  exit 0;
}

store(){
   response=$(curl -s -H 'Content-Type: application/json' -w %{http_code} -X POST --data "$data" http://$domain:$port/update/measurements)
   http_code=$(echo $response | tail -c 4)
   body=$(echo $response| rev | cut -c 4- | rev )
   sed -i "/$NAME/c\\$NAME: $body $domain http_code: $http_code" /etc/mazi/rest.log
}


########################################
#              main                    #
########################################

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
        -d|--duration)
        DUR="$2"
        shift
        ;;
        -i|--interval)
        interval="$2"
        shift
        ;;
        -a|--available)
        register_sensors
        available_fun
	;;
        -D|--domain)
        domain="$2"
        shift
        ;;
        --status)
        status_fun
        ;;
        --help)
        usage
        ;;
        *)
        #receives the sensor argumnets
        argum[$i]=$1
        i=$(($i+1))
        ;;
   esac
   shift     #past argument or value
done

#####Check the sensor name######
if [ ! $NAME ];then
    echo "Please complete the sensor name"
    echo ""
    usage 
    exit 0;
fi
################################

### Take the sensor's ID #####
#[ $STORE ] && register_sensors
[ $STORE ] && sensor_id

[ ! -f /etc/mazi/rest.log -o ! "$(grep -R "$NAME:" /etc/mazi/rest.log)" ] && echo "$NAME:" >> /etc/mazi/rest.log

#### move sensors of sensehat####
if [ $NAME = "sensehat" ];then
  for item in ${argum[@]}
  do
    if [ "-m" == "$item" -o "-g" == "$item" -o "-ac" == "$item" ]; then
        mv_sensors="TRUE"
    fi
  done
  [ $mv_sensors ] && python lib/$NAME.py ${argum[@]}

fi

endTime=$(( $(date +%s) + $DUR )) # Calculate the script's Duration.
while [ true ]; do
 target_time=$(( $(date +%s)  + $interval ))
 make_data 
 #### STORE OPTION #####
 [ $STORE ] && store &
 current_time=$(date +%s)
 [ $(($target_time - $current_time)) -gt 0 ] && sleep $(($target_time - $current_time))
 [ $(date +%s) -ge $endTime ] && exit 0; 
done
 
#set +
