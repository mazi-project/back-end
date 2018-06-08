#!bin/bash
set -x
# install nodogsplash
if [ ! -d /root/nodogsplash ];then
  cd /root/
  git clone https://github.com/nodogsplash/nodogsplash.git
  cd nodogsplash
  git checkout v1
  make
  make install
fi

cp /root/back-end/templates/online.txt /etc/nodogsplash/
cp /root/back-end/templates/offline.txt /etc/nodogsplash/

## create nodogsplash service
if [ ! -f /etc/init.d/nodogsplash ];then
  cp /root/back-end/templates/nodogsplash /etc/init.d/
  chmod +x /etc/init.d/nodogsplash
  update-rc.d nodogsplash defaults
  systemctl daemon-reload
fi

## hostapd tempates
cp /root/back-end/templates/template_80211n.txt /etc/hostapd/
cp /root/back-end/templates/replace.sed /etc/hostapd/


if [ -z "$(cat /proc/modules | grep batman)" ];then
  ## install batctl (mesh) ##
  cd /root/
  apt-get install batctl
  echo "batman-adv" >> /etc/modules
  modprobe batman-adv
fi

## remove old iptables ##
iptables -F
iptables -F -t nat
iptables -F -t mangle
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables-save | sudo tee /etc/iptables/rules.v4

## update rc.local ###
sed -i '/service nodogsplash start/d' /etc/rc.local
if [ -z "$(cat /etc/rc.local | grep "bash /root/back-end/mazi-internet.sh")" ];then
  sudo sed -i '/#END RASPIMJPEG SECTION/ a \bash /root/back-end/mazi-internet.sh -m $(jq -r .mode /etc/mazi/mazi.conf)' /etc/rc.local
fi

## update /etc/network/interfaces
sed -i '/allow-hotplug wlan0/d' /etc/network/interfaces
sed -i '/iface wlan0 inet manual/d' /etc/network/interfaces
sed -i '/#    wpa-conf \/etc\/wpa_supplicant\/wpa_supplicant.conf/d' /etc/network/interfaces
sed -i '/    wpa-conf \/etc\/wpa_supplicant\/wpa_supplicant.conf/d' /etc/network/interfaces
sed -i '/allow-hotplug wlan1/d' /etc/network/interfaces
sed -i '/iface wlan1 inet manual/d' /etc/network/interfaces
sed -i '/iface wlan0 inet static/d' /etc/network/interfaces
sed -i '/address 10.0.0.1/d' /etc/network/interfaces
sed -i '/netmask 255.255.255.0/d' /etc/network/interfaces
sed -i '/gateway 10.0.0.1/d' /etc/network/interfaces


#sh /root/back-end/mazi-internet.sh -m offline
intface=$(grep 'interface' /etc/hostapd/hostapd.conf| sed 's/interface=//g')
ssid=$(grep 'ssid' /etc/hostapd/hostapd.conf| sed 's/ssid=//g')
channel=$(grep 'channel' /etc/hostapd/hostapd.conf| sed 's/channel=//g')
password=$(grep 'wpa_passphrase' /etc/hostapd/hostapd.conf| sed 's/wpa_passphrase=//g')
[ -z $password ] && password="-"
if [ "$password" = "-" ];then
  bash /root/back-end/mazi-wifi.sh -s $ssid -c $channel  -i $intface
else
  bash /root/back-end/mazi-wifi.sh -s $ssid -c $channel -p $password -i $intface
fi

bash /root/back-end/mazi-internet.sh -m $(jq -r .mode /etc/mazi/mazi.conf)

cp templates/splash.html /etc/nodogsplash/htdocs/

cp /root/back-end/templates/splash.html /etc/nodogsplash/htdocs/
cp /root/back-end/templates/MAZI_bw.png /etc/nodogsplash/htdocs/images/

set +x
