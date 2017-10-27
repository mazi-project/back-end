#!bin/bash

#configuration of rc.local file 

sudo sed -i '/ifdown wlan0/,/ifconfig wlan0 10.0.0.1/d' /etc/rc.local
sudo sed -i '/ifconfig wlan0 10.0.0.1/ a \sudo sh /root/back-end/wifiap.sh' /etc/rc.local

#configuration of ssh_config file 
sudo sed -i '$ a \Host 10.0.2.2\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null' /etc/ssh/ssh_config

#sshpass installation
sudo apt-get --yes install sshpass

#speedtest-cli installation
sudo apt-get --yes install python-pip
sudo pip install speedtest-cli 


#execute bash script from any location
#sudo export PATH=$PATH:/root/back-end/
#sudo echo 'export PATH="/root/back-end:$PATH"' >> ~/.bashrc
#. ~/.bashrc
#sudo chmod o+x /root/back-end/*

#drivers of available antennas 

sudo install-wifi -u 8188eu
sudo install-wifi -u 8812au
sudo install-wifi -u mt7610
sudo install-wifi -u 8188eu
