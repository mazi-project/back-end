#!bin/bash
#set -x 
# install nodogsplash
cd /root/
git clone https://github.com/nodogsplash/nodogsplash.git
cd nodogsplash
git checkout v1
make
make install
cp /root/back-end/templates/online.txt /etc/nodogsplash/
cp /root/back-end/templates/offline.txt /etc/nodogsplash/

## create nodogsplash service
cp /root/back-end/templates/nodogsplash /etc/init.d/
chmod +x /etc/init.d/nodogsplash
update-rc.d nodogsplash defaults
systemctl daemon-reload


## hostapd tempates
cp /root/back-end/templates/template_80211n.txt /etc/hostapd/
cp /root/back-end/templates/replace.sed /etc/hostapd/



## install batctl (mesh) ##
cd /root/
apt-get install batctl
echo "batman-adv" >> /etc/modules
modprobe batman-adv 


## remove old iptables ##
iptables -F
iptables -F -t nat
iptables -F -t mangle
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables-save | sudo tee /etc/iptables/rules.v4

## update rc.local ###
sudo sed -i "/#ifconfig wlan0 10.0.0.1/ a \service nodogsplash start" /etc/rc.local

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
ssid=$(bash /root/back-end/mazi-current.sh -s | awk '{print $NF}')
channel=$(bash /root/back-end/mazi-current.sh -c | awk '{print $NF}')
password=$(bash /root/back-end/mazi-current.sh -p | awk '{print $NF}')
[ "$password" == "-" ] && bash /root/back-end/mazi-wifi.sh -s $ssid -c $channel ||  bash /root/back-end/mazi-wifi.sh -s $ssid -c $channel -p $password

bash /root/back-end/mazi-internet.sh -m $(jq -r .mode /etc/mazi/mazi.conf)

cp templates/splash.html /etc/nodogsplash/htdocs/

#set +x
