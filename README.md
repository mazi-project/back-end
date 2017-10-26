# MAZI back-end
These scripts have been created in order to serve the requirements of the MAZI project. Most of these scripts they are used from administration and user interface of mazi toolkit.
Below is a short guide to show you, how you can execute these scripts from the command line in order to modify your mazi toolkit.

You can clone this repository into a [MAZI zone image] (http://nitlab.inf.uth.gr/mazi-img/) and configure accordingly your MAZI zone.



## Prerequirements
Install the following packages:
```
$ apt-get install python-pip
$ pip install speedtest-cli
$ apt-get install sshpass
$ apt-get install jq
```

## Guide

### mazi-antenna.sh ###
This script is responsible to detect if you have connected any USB dongle on raspberry pi board. In addition, you can manage this dongle in order to connect raspberry pi to a wifi network 

Usage:
```
sudo sh mazi-antenna.sh  [options]
[options]
-a,--active                 Shows if the wifi dongle exists
-s,--ssid                   Set the name of wifi network
-p,--password               Set the password of wifi network
-l,--list                   Displays the list of available wifi
-h,--hidden                 Connect to hidden network
-d,--disconnect             Disconnect from network

```

### mazi-wifi.sh ###
The mazi-wifi.sh detects the device which you have defined to executed the Wireless Access Point (OWRT router or Raspberry Pi). Also, you have the ability to modify the configuration of wifi AP, for example, you can change the ssid, channel, etc.

Usage:
```
sudo sh mazi-wifiap.sh  [options]
 [options]
-s,--ssid                    Set the name of your WiFi network
-c,--channel                 Set channel number
-p,--password                Set your passphrase (WiFi password)
-w,--wpa  [OFF/off]          Turn off wireless network security
```

### mazi-resetpswd.sh ###
In case you have forgotten your administrator password, you have the ability to restore them with this script. Once you will run the mazi-resetpaswrd.sh, the administrator password change to "1234", now you can change your code to whatever you want.

Usage:
```
sudo sh mazi-resetpswd.sh
```

### mazi-sense.sh ###
This script can detect the type of sensor which is connected to your raspberry pi board. You have the choice to request the measurements of the sensor periodically and for a specific duration. One more functionality is that to send the measurements via a rest API in a local database or in a remote database through the --domain argument.

> Note: The available sensor is the sensehat and sht11.

Usage:
```
sudo sh mazi-sense.sh [SenseName] [Options] [SensorOptions]

[SenseName]
-n,--name                    Set the name of the sensor

[Options]
-s , --store                 Store the measurements in the Database
-d , --duration              Duration in seconds to take a measurement
-i , --interval              Seconds between periodic measurement
-a , --available             Displays the status of the available sensors
--domain                     Set a remote server domain.( Default is localhost )

[SensorOptions]
{sht11}
-t , --temperature            Get the Temperature
-h , --humidity               Get the Humidity

{sensehat}
-t , --temperature             Get the Temperature
-h , --humidity                Get the Humidity
```

### mazi-app.sh ###
You can easily start, stop or control the status of an application with this script. 
> Note: this script has been created only for, etherpad, mazi-board, mazi-princess.

Usage:
```
sudo sh mazi-app.sh  [options] <application>

[options]
-a, --action [start,stop,status] <application>     Set the action and name of application
```

### mazi-domain.sh ###
You have the choice to change the current domain (portal.mazizone.eu) to whatever you want or to set as the default page a specific application.
> Note: The current applications is guestbook, etherpad, framadate, nextcloud, wordpress or portal for the user interface of mazi toolkit.

Usage:
```
sudo sh mazi-domain.sh [options]
[options]
-d,--domain              Set a new Domain of portal page
-s,--splash              Set a application or portal as a basic page
```

### mazi-internet.sh ###
You have the ability to choose between three modes, offline, dual and restricted. In offline mode, users haven't access to the internet and they redirect to the user interface of the portal. In dual mode, raspberry pi provides internet to users. If you want to browse the user interface of the portal, you should go to  the portal.mazizone.eu .The restricted mode hasn't implemented yet.

Usage:
```
sudo sh internet.sh -m      <offline/dual/restricted>
```

### mazi-current.sh ###
This script is responsible to display the current configuration of the raspberry pi board. For example, it has the ability to display the current ssid, channel, mode, etc.

Usage:
```
sudo sh mazi-current.sh  [options]
[options]
-i,--interface               Shows the name of the interface
-c,--channel                 Shows the channel to use
-m,--mode                    Shows the mode of Access Point
-p,--password                Shows the password of the Access Point
-s,-ssid                     Shows the name of the WiFi Access Point
-d,--domain                  Shows the new domain of toolkit
```

### mazi-router.sh ###
The mazi-router.sh configures OpenWrt router as an external antenna of raspberry pi which broadcasts the local WiFi network mazizone

Usage:
```
sudo sh mazi-router.sh [options]
[options]
-s,--status                  Displays the status of router OpenWrt 
-a,--activate                Starts the process to configure the OpenWrt router
-d,--deactivate              Restores the initial settings
```
### mazi-stat.sh ###
This script provides the statistics information about the raspberry pi board, like board temperature, CPU usage, etc. One more functionality is that to send the measurements through a rest API in a local database or in a remote database through the --domain argument.

Usage:
```
sudo sh mazi-stat.sh [options]
[options]
-t,--temp                 Displays the CPU core temperature
-u,--users                Displays the total online users
-c,--cpu                  Displays the CPU usage
-r,--ram                  Displays the RAM usage
-s,--storage              Displays the percentage of the available storage
-n,--network              Displays the Download/Upload speed
-d,--domain               Set a remote server domain.( Default is localhost )
--status                  Displays the status of store process
--store                   [enable] , [disable ] or [flush]

```

### mazi-appstat.sh ###
This script provides the ability to collect statistics measurements from a set of applications,  and then to write these measurements in a local or remote database. 

> Note: The available applications are these, guestbook, etherpad and framadate

Usage:
```
sudo sh mazi-appstat.sh [Application name] [options]

[Application name]
-n,--name          Set the name of the application

[options]
--store                   [enable] , [disable ] or [flush]
--status                  Displays the status of store process
-d,--domain               Set a remote server domain.(Default is localhost)
```

## License

See the [LICENSE] (https://github.com/mazi-project/back-end/blob/master/LICENSE) file for license rights and limitations (MIT).
