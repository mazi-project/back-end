
#!/bin/bash 

#The mazi-current.sh script displays the settings of the Wi-Fi Access Point that has been created in this MAZI Zone.
#You can view information such as the name , the password and the channel of the Wi-Fi Access Point. You can also see
#the domain you are using for the portal page, as well as the active interface that broadcast the Wi-Fi Access Point-
#in case you have plugged in an OpenWRT router. Finally, this script informs you about the mode of your Wi-Fi Access Point.

#set -x
usage() { echo "Usage: sudo sh current.sh  [options]" 
          echo " " 
          echo "[options]" 
          echo "-i,--info    [wifi|internet..]     Shows the interface that used for AP or for internet connection respectively."
          echo "              wifi                 Interface for Access Point"
          echo "              internet             Interface for internet connection"
          echo "              mesh                 Interface for mesh network"
          echo "              all                  Shows all available interfaces"
          echo "-n,--netstat                       Shows the status of the internet network"
          echo "-s,--ssid                          Shows the name of the Wi-Fi network"
          echo "-c,--channel                       Shows the Wi-Fi channel in use"
          echo "-p,--password                      Shows the pasword of the  Wi-Fi network"
          echo "-d,--domain                        Shows the network domain of the MAZI Portal"
          echo "-m,--mode                          Shows the mode of the Wi-Fi network"
          echo "-w,--wifi                          Shows the device that broadcaststhe Wi-Fi AP (pi or OpenWRT router)" 1>&2; exit 1; }

interface(){
  if [ $1 = "wifi" ];then
     [ $ROUTER ] && echo "wifi_interface br-lan"
     [ -z $ROUTER ] && echo "wifi_interface $(cat /etc/hostapd/replace.sed| grep "intface" | awk -F'[/|/]' '{print $3}')" 
  elif [ $1 = "internet" ];then
     internet_interface=$(ps aux | grep wpa_supplicant | grep -o '\-i.*' | awk '{print $2}')
     [ $internet_interface ] && internet_interface=$(iwconfig 2>/dev/null | grep $internet_interface | awk '{print $1}')
     [ $internet_interface ] && echo "internet_interface $internet_interface" || echo "internet_interface -"
  elif [ $1 = "mesh" ];then
     mesh_interface="-"
     ifaces=$(netstat -i |  awk '{print $1}' | grep -v "Kernel" | grep -v "Iface")
     #read -a ifaces <<<$ifaces
     for i in ${ifaces[@]};do
       if [ "$(iwconfig $i 2>/dev/null | grep Mode | awk '{print $1}')" = "Mode:Ad-Hoc" ];then
         mesh_interface=$i
       fi
     done
     [ $mesh_interface ] && echo "mesh_interface $mesh_interface" || echo "mesh_interface -"
  elif [ $1 = "all" ];then
     ifaces=$(ifconfig -a | awk '{print $1}' | grep wlan| tr -d :)
    # read -a ifaces <<<$ifaces
     count=1
     for i in ${ifaces[@]};do
        [ "$(ifconfig $i | grep "b8:27:eb")" ] && name="raspberry" 
        [ -z "$(ifconfig $i | grep "b8:27:eb")" ] && name=usb$count && count=$((count+1))
        echo "interface $i $name"
     done
  else
    usage
    exit 0;
  fi
}

WRT="10.0.2.2"
PSWD="mazi"
conf="/etc/mazi/mazi.conf"

if [ -f /etc/mazi/router.conf ];then
  if [ "$(cat /etc/mazi/router.conf)" = "active" ];then
    ROUTER="TRUE"
    dev="OpenWrt router"
  fi
fi
if [ "$(ps aux | grep hostapd | grep -v 'grep')" ];then
  dev="Raspberry pi"
fi

while [ $# -gt 0 ]
do
key="$1"

case $key in
    -i |--info)
    interface $2
    shift
    ;;
    -d |--domain)
    DOMAIN="YES"
    ;; 
    -s|--ssid)
    SSID="YES"
    ;;
    -c|--channe)
    CHANNEL="YES"
    ;;
    -p|--password)
    PASSWORD="YES"
    ;;
    -m|--mode)
    MODE="YES"
    ;;
    -n|--netstat)
    NETWORK="YES"
    ;;
    -w|--wifi)
    DEVICE="TRUE"
    ;;
    *)
       # unknown option
    usage   
    ;;
esac
shift #past argument
done

## print channel
if [ "$CHANNEL" = "YES" ]; then
  if [ "$ROUTER" ];then 
    channel=$(sudo sshpass -p "$PSWD" ssh root@$WRT "grep 'channel' /etc/config/wireless | sed 's/option channel//g'| grep -o  [^\']* | xargs")
  else
    channel=$(cat /etc/hostapd/replace.sed| grep "channel" | awk -F'[/|/]' '{print $3}') 
  fi
  echo "channel $channel"
fi

## print network status
if [ "$NETWORK" = "YES" ];then
    ping 8.8.8.8 -c 1 -W 1 | grep "1 received" > /dev/null && echo "ok" || echo "error"
fi

## print ssid
if [ "$SSID" = "YES" ]; then
  if [ "$ROUTER" ];then
     ssid=$(sudo sshpass -p "$PSWD" ssh root@$WRT "grep 'ssid' /etc/config/wireless | sed 's/option ssid//g'| grep -o  [^\']* | xargs")
  else
    ssid=$(cat /etc/hostapd/replace.sed| grep "ssid" | awk -F'[/|/]' '{print $3}')  
  fi
  echo "ssid $ssid"
fi


## print new domain
if [ $DOMAIN ]; then
  echo "domain $(grep 'ServerName' /etc/apache2/sites-available/portal.conf | awk '{print $2}')"
fi


## print password if it exists
if [ "$PASSWORD" = "YES" ]; then
  key="-"
  if [ "$ROUTER" ];then
     pswd=$(sudo sshpass -p "$PSWD" ssh root@$WRT "grep 'option encryption' /etc/config/wireless | sed 's/option encryption//g'| grep -o [^\']* | xargs")
     if [ "$pswd" != "none" ];then
         key=$( sudo sshpass -p "$PSWD" ssh root@$WRT "grep 'option key' /etc/config/wireless | sed 's/option key//g'| grep -o [^\']* | xargs")
     fi  
  else
     paswd=$(grep 'wpa_passphrase' /etc/hostapd/hostapd.conf| sed 's/wpa_passphrase=//g')
     if [ "$paswd" != "" ];then
         key=$(cat /etc/hostapd/replace.sed| grep "password" | awk -F'[/|/]' '{print $3}')
     fi
  fi 
  echo "password $key"
fi

## print mode
if [ "$MODE" = "YES" ]; then
   if [ -f $conf ]; then
     echo mode $(jq ".mode" $conf) 
   else
     echo "mode -"
   fi 
fi

if [ "$DEVICE" ];then
  echo "device $dev"
fi

#set +x

