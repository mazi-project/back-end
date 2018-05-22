#!bin/bash

# install nodogsplash
cd /root/
git clone https://github.com/nodogsplash/nodogsplash.git
cd nodogsplash
git checkout v1
make
make install
cp /root/back-end/templates/online.txt /etc/nodogsplash/
cp /root/back-end/templates/offline.txt /etc/nodogsplash/

## hostapd tempates
cp /root/back-end/templates/template_80211n.txt /etc/hostapd/
cp /root/back-end/templates/replace.sed /etc/hostapd/

## install batctl (mesh) ##
cd /root/
apt-get install batctl
echo "batman-adv" >> /etc/modules
modprobe batman-adv 

## remove certificates ##
## ?


## remove old iptables ##
iptables -F
iptables -F -t nat
iptables -F -t mangle
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables-save | sudo tee /etc/iptables/rules.v4

sh /root/back-end/mazi-internet.sh -m offline

## update rc.local ###
sudo sed -i '/\/sbin\/ifconfig wlan0 10.0.0.1/d' /etc/rc.local 
/root/nodogsplash/nodogsplash 2 > /dev/null
sudo sed -i "/wifiap.sh/ a \\/root\/nodogsplash\/nodogsplash 2 > \/dev\/null" /etc/rc.local

## update /etc/network/interfaces
sed -i '/allow-hotplug wlan0/d' /etc/network/interfaces
sed -i '/iface wlan0 inet manual/d' /etc/network/interfaces
sed -i '/wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf/d' /etc/network/interfaces
sed -i '/allow-hotplug wlan1/d' /etc/network/interfaces
sed -i '/iface wlan1 inet manual/d' /etc/network/interfaces


