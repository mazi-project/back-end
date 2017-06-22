# MAZI back-end
This is the back-end scripts of the MAZI toolkit. You can clone this repository into a [MAZI zone image] (http://nitlab.inf.uth.gr/mazi-img/) and configure accordingly your MAZI zone.

## wifiap.sh
The *wifiap.sh* script creates a Wi-Fi Access Point according to the configuration you define. The script modifies the file */etc/hostapd/hostapd.conf* and then restarts the hostapd service.

Usage:
```
sudo sh wifiap.sh  [options]
```
[options]

-s,--ssid______________________The name of the WiFi Access Point

-c,--channel...................The channel to use

-w,--wpa.......................Set off/OFF if you want to turn off wireless network security

-p,--password..................The password of the Access Point


**Examples**

Set up a Wi-Fi Access Point
```
sudo sh wifiap.sh  -s mazizone -c 6 -p mazizone
```

change the name of the Access Point
```
sudo sh wifiap.sh -s John
```

**Password**

Its length should be more than 8 characters.


## internet.sh

The *internet.sh* script changes the mode of the MAZI zone (offline, dual and restricted).

offline: the local Wi-Fi network is not connected to the Internet

dual: the local Wi-Fi network is connected to the Internet

restricted: some of the clients of the local Wi-Fi network have access to the Internet

Usage:
```
sudo sh internet.sh -m <offline/dual/restricted>
```
## mazi-stat.sh

The *mazi-stat.sh* script displays the statistics of the current Raspberry pi. 

Script's requirements
```
sudo apt-get install python-pip
sudo pip install speedtest-cli
```

Usage:
```
sudo sh mazi-stat.sh [options]
```
[options]

  -t,--temp.................Displays the CPU core temperature                                                           
  -u,--users................Displays the total online users                                                             
  -c,--cpu..................Displays the CPU usage                                                                       
  -r,--ram..................Displays the RAM usage                                                                       
  -s,--storage..............Displays the percentage of the available storage                                             
  -n,--network..............Displays the Download/Upload speed                                                           

## mazi-app.sh

The *mazi-app.sh* script administers the applications of the MAZI zone toolkit(start, stop and status).

start: start the application

stop: stop the application

status: shows the status of the applications

Usage:
```
sudo sh mazi-app.sh -a <start/stop/status> <application>
```

## current.sh

The *current.sh* script displays the features of the MAZI zone WIFI .

Usage:
```
sudo sh current.sh  [options]
```                                                                                                                       
[options]                                                                                                                 
  -i,--interface....................Shows the name of the interface                                                       
  -c,--channel......................Shows the channel to use                                                               
  -m,--mode.........................Shows the mode of Access Point                                                         
  -p,--password.....................Shows the password of the Access Point                                                 
  -s,-ssid..........................Shows the name of the WiFi Access Point                                                   
  -d,--domain.......................Shows the new domain of toolkit                                                                     

## antenna.sh

The *antenna.sh* script connects the second wifi dongle antenna to the internet through a wifi network.

Usage:
```
sudo sh antenna.sh  [options]
```                                                                                                                       
[options]                                                                                                                 
  -a,--active.......................Shows if the wifi dongle exists                                                       
  -s,--ssid.........................Set the name of wifi network                                                           
  -p,--password.....................Set the password of wifi network                                                       
  -l,--list.........................Displays the list of available wifi                                                   
  -h,--hidden.......................Connect to hidden network                                                             
  -d,--disconnect...................Disconnect from network                                                               
                                                                                                                           
## mazi-sense.sh

The *mazi-sense.sh* script manages all the available sensors which are plugging on the raspberry pi 

Usage:
```
sudo sh mazi-sense.sh [SenseName] [Options] [SensorOptions]
```                                                                                                                       
[SenseName]                                                                                                               
  -n,--name.........................Set the name of the sensor                                                             
                                    {sht11,sensehat....}                                                               
[Options]                                                                                                                 
  -s , --store.......................Store the measurements in the Database                                               
  -d , --duration....................Duration in seconds to take a measurement                                             
  -i , --interval....................Seconds between periodic measurement                                                 
  -a , --available...................Displays the status of the available sensors                                         
                                                                                                                           
[SensorOptions]                                                                                                           
  {sht11}                                                                                                                 
  -t , --temperature.................Get the Temperature                                                                   
  -h , --humidity....................Get the Humidity                                                                     
                                                                                                                           
  {sensehat}                                                                                                               
  -t , --temperature.................Get the Temperature                                                                   
  -h , --humidity....................Get the Humidity                                                                     


## mazi-domain                                                                                                                           
                                                                                                                                         
This script changes the domain name of mazi toolkit                                                                                     
Usage:
```
sudo sh mazi-domain.sh -d < new domain >
```                                                                                                                       

## mazi-resetpswd.sh                                                                                                                     
                                                                                                                                        
This script reset the  administrator password of the portal to "1234"                                                                   
Usage:
```
sudo sh mazi-resetpswd.sh
```     
## License

See the [LICENSE] (https://github.com/mazi-project/back-end/blob/master/LICENSE) file for license rights and limitations (MIT).
