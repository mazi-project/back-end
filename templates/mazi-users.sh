path="/root/back-end"
log="/etc/mazi"
conf="/etc/mazi/mazi.conf"
if [ "$(bash $path/current.sh -w)" = "device OpenWrt router" ];then
   ROUTER="TRUE"
fi

wifi_intface=$(bash $path/mazi-current.sh -i wifi | awk '{print $2}')
sudo touch $log/users.log
sudo chmod 777 $log/users.log

while true; do
	if [ "$ROUTER" ];then
   		response=$(sudo arp-scan --interface=eth0 10.0.2.0/24 --numeric --quiet --ignoredups | grep -E '([a-f0-9]{2}:){5}[a-f0-9]{2}')
        printf "%s %s \n" "${response[@]}" > $log/users.log
        
	else
   		response=$(sudo arp-scan --interface=wlan1 10.0.0.0/24 --numeric --quiet --ignoredups | grep -E '([a-f0-9]{2}:){5}[a-f0-9]{2}')
        printf "%s %s \n" "${response[@]}" > $log/users.log
	fi
done
