#!/bin/bash

#This script manages all available  sensors 
#
# Usage: sudo sh mazi-sense.sh [senseName] [options]
#set  -x

##### Initialization  ######
cd /root/back-end
DUR="0"     #initialization of duration
interval="0"     #initialization of interval
domain="localhost"
conf="/etc/mazi/mazi.conf"
path_sense="/root/back-end/lib"
IP="$(ifconfig wlan0 | grep 'inet addr' | awk '{printf $2}'| grep -o '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*')"
i=0

#### Functions ####
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

 device_id=$(curl -s -X GET -d @$conf http://$domain:4567/device/id)
 [ ! $device_id ] && device_id=$(curl -s -X POST -d @$conf http://$domain:4567/monitoring/register)

 ID=$(curl -s -H 'Content-Type: application/json' -X GET --data "{\"deployment\":$(jq ".deployment" $conf),\"sensor_name\":\"$NAME\",\"ip\":\"$IP\",\"device_id\":\"$device_id\"}" http://$domain:4567/sensors/id)
 ### Register the sensor ####
 [ ! $ID ] && ID=$(curl -s -H 'Content-Type: application/json' -X POST --data "{\"deployment\":$(jq ".deployment" $conf),\"sensor_name\":\"$NAME\",\"ip\":\"$IP\",\"device_id\":\"$device_id\"}" http://$domain:4567/sensor/register)

 ### Create the table measurements or update it with new types of sensors
 curl -s -H "Content-Type: application/json" -H 'Accept: application/json' -X POST -d "{\"senstypes\":$senstypes}" http://$domain:4567/create/measurements > /dev/null
}


available_fun(){

 read -a sensors <<<$(find lib/ -maxdepth 1 -name "*.py" -exec basename \{} .py \;)
 for s in ${sensors[@]}
 do
    var=$(python lib/$s.py --detect 2>&1)
    if [ "$var" == "$s" ];then
       SERVICE="$(ps -ef | grep $s | grep -v 'grep'| grep -v '\-m\|\-ac\|\-g')"
       [ "$SERVICE" != "" ] && echo "$s active $IP" || echo "$s inactive $IP"
    fi
 done
 exit 0;
}


status_fun(){
  read -a sensors <<<$(find lib/ -maxdepth 1 -name "*.py" -exec basename \{} .py \;)
  for s in ${sensors[@]}
  do
     var=$(python lib/$s.py --detect 2>&1)
     [ "$var" == "$s" ] &&  NAME=$s
  done
  status_call $NAME
  [ "$(ps aux | grep "store\|\-s" | grep "mazi-sense.sh" | grep "\-n $NAME "| grep -v 'grep'| grep -v '\-m\|\-ac\|\-g')" ] && echo "$NAME active $call_st $error" || echo "$NAME inactive"
  exit 0;
}

store(){
   response=$(curl -s -H 'Content-Type: application/json' -w %{http_code} -X POST --data "$data" http://$domain:4567/update/measurements)
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
 
#set +x

