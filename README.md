# MAZI backend
The MAZI Backend has been designed and developed in order to handle low-level communication between the MAZI toolkit's hardware and the MAZI Portal. Moreover, it can be used by developers or advanced MAZI toolkit users to configure a MAZI Zone or build one from scratch. You can find below a guide on how to execute these scripts from the command line in order to modify your MAZI Zone.

In case you are using one of the [MAZI Zone images](http://nitlab.inf.uth.gr/mazi-img/), you can find the back-end scripts in the following folder
```
cd /root/back-end
```
Also, you can clone this repository into a [Raspbian image](https://www.raspberrypi.org/downloads/) to build a MAZI Zone from scratch, check [here](http://nitlab.inf.uth.gr/mazi-guides/backend.html) for more info.



## Prerequirements
Install the following packages:
```
$ apt-get install python-pip
$ pip install speedtest-cli
$ apt-get install sshpass
$ apt-get install jq
$ apt-get intsall sqlite3
$ apt-get install batctl
$ echo "batman-adv" >> /etc/modules
```

## Guide

### mazi-antenna.sh ###
The	mazi-antenna.sh	script	has	been	created	in	order	to	manage	an	external	USB	adapter	that	is	connected	to	the	Raspberry	Pi.	This	script	is	able	to	check	if	a	USB	adapter	is	connected	to	the	Raspberry	Pi.	In	addition,	you	can	discover	the	available	networks	in	range	and	connect	to	one	of	them.	Finally,	you	can	disconnect	the	USB	adapter	from	the	connected	Wi-Fi	network.

Usage:
```
sudo sh mazi-antenna.sh  [options]
[options]
-i,--interface              Set the interface
-a,--active                 Shows the SSID of the interface  
-s,--ssid                   Sets the SSID of the Wi-Fi network
-p,--password               Sets the password of the Wi-Fi network
-l,--list                   Displays a list of the available Wi-Fi networks in range
-h,--hidden                 Connect to hidden Wi-Fi network
-d,--disconnect             Disconnect the USB adapter from Wi-Fi network

```

### mazi-wifi.sh ###
The	mazi-wifi.sh	script	is	responsible	for	creating	the	Wi-Fi	Access	Point	on	the	Raspberry	Pi.	With	this	script,	you	can	also	modify	the	settings	of	your	Wi-Fi	Access	Point.

Usage:
```
sudo sh mazi-wifiap.sh  [options]
 [options]
-i,--interface               Set the interface
-s,--ssid                    Sets the name of the Wi-Fi network
-c,--channel                 Sets the Wi-Fi channel
-p,--password                Sets the Wi-Fi password
-w,--wpa  [OFF/off]          Turns off wireless network security
```
You can simply start (or restart the Wi-Fi Access Point if it is already started) without passing any argument.
```
sudo sh mazi-wifiap.sh
```

### mazi-resetpswd.sh ###
In	case	you	have	forgotten	your	MAZI	Portal	administrator	password,	this	script	enables	its	recovery.	Once	you	run	the	mazi-resetpswd.sh,	the	password	changes	back	to	the	default	"1234"	and	then	you	can	access	the	MAZI	Portal	and	change	it	through	the	first-contact	page.

Usage:
```
sudo sh mazi-resetpswd.sh
```

### mazi-sense.sh ###
The	mazi-sense.sh	script	has	been	created	in	order	to	manage	various	sensors	connected	to	the	Raspberry	Pi.	This	script	can	detect	the	connected	sensor	devices	and	consequently	collect	measurements	periodically	with	a	specific	duration	and	interval	between	measurements.	In	addition,	it	can	store	these	measurements	in	a	local	or	remote	database	and	check	the	status	of	the	storage	procedure,	as	well.	

Usage:
```
sudo bash mazi-sense.sh [SenseName] [Options] [SensorOptions]

[SenseName]
-n,--name                    The name of the sensor

[Options]
-s , --store                 Stores the measurements in the database
-d , --duration              Duration in seconds to take a measurements
-i , --interval              Seconds between periodic measurements
-a , --available             Displays the status of the available sensors
-D,--domain                  Sets a remote server domain (default is localhost)
--status                     Displays the status of store process

[SensorOptions]
-t , --temperature            Get the Temperature
-h , --humidity               Get the Humidity
-p , --pressure               Get the current pressure in Millibars
-m , --magnetometer           Get the direction of North
-g , --gyroscope              Get a dictionary object indexed by the strings x, y and z
                              The values are Floats representing the angle of the axis in degrees
-ac , --accelerometer         Get a dictionary object indexed by the strings x, y and z
                              The values are Floats representing the acceleration intensity of the axis in Gs
```

### mazi-app.sh ###
The	mazi-app.sh	script	enables	the	control	of	the	status	of	the	installed	applications	such	as	the	Etherpad,	the	Guestbook,	the	LimeSurvey	and	the	Interview-archive.	You	can	start,	stop	or	display	the	status	of	the	above	applications.	

Usage:
```
sudo sh mazi-app.sh  [options] <application>

[options]
-a, --action [start,stop,status] <application>    Controls the status of the installed applications

```

### mazi-domain.sh ###
The	mazi-domain.sh	script	enables	the	modification	of	the	MAZI	Portal’s	domain	and	the	change	of	the	splash	page.

Usage:
```
sudo sh mazi-domain.sh [options]
[options]
-d,--domain              Sets a new network domain of the portal
-s,--splash              Sets a new splash page
```

### mazi-internet.sh ###
The	mazi-internet.sh	script	is	able	to	modify	the	mode	of	your	Wi-Fi	Access	Point	–	currently	-	between	offline	and	dual	as	the	managed	mode	has	not	been	implemented	yet.	In	the	offline	mode,	clients	of	the	Wi-Fi	Access	Point	have	not	access	to	the	Internet	and	are	permanently	redirected	to	the	Portal	splash	page.	In	the	dual	mode,	the	Raspberry	Pi	provides	Internet	access	through	either	the	Ethernet	cable	or	an	external	USB	Wi-Fi	adapter.

Usage:
```
sudo sh internet.sh [options]
[options]
-m,--mode  [offline/dual/managed]   Sets the mode of the Wi-Fi Access Point
```

### mazi-current.sh ###
The	mazi-current.sh	script	displays	the	settings	of	the	Wi-Fi	Access	Point	that	has	been	created	in	this	MAZI	Zone.	You	can	view	information	such	as	the	name,	the	password	and	the	channel	of	the	Wi-Fi	Access	Point.	You	can	also	see	the	domain	you	are	using	for	the	portal	page,	as	well	as	the	active	interface	that	broadcasts	the	Wi-Fi	Access	Point	-	in	case	you	have	plugged	in	an	OpenWRT	router.	Finally,	this	script	informs	you	about	the	mode	of	your	Wi-Fi	Access	Point	(offline,	dual,	managed).

Usage:
```
sudo sh mazi-current.sh  [options]
[options]
-i,--interface  [wifi|internet..]  Shows the interface that used for AP or for internet connection respectively
                wifi               Interface for Access Point
                internet           Interface for internet connection
                mesh               Interface for mesh network
                all                Shows all available interfaces
-c,--channel                       Shows the Wi-Fi channel in use
-m,--mode                          Shows the mode of the Wi-Fi network
-p,--password                      Shows the password of the Wi-Fi network
-s,-ssid                           Shows the name onan f the Wi-Fi network
-d,--domain                        Shows the network domain of the MAZI Portal
-w,--wifi                          Shows the device that broadcasts the Wi-Fi AP (pi or OpenWRT router)
```

### mazi-router.sh ###
The	mazi-router.sh	script	is	used	for	the	management	of	the	OpenWrt	Router	connected	to	this	MAZI	Zone.	After	connecting	an	OpenWrt	Router	this	script	is	able	to	detect	it	and	control	the	status	of	the	connection,	(activate/deactivate).	

Usage:
```
sudo sh mazi-router.sh [options]
[options]
-s,--status                  Displays if the OpenWRT router exists 
-a,--activate                Activates	the	OpenWRT	router	as	the	Wi-Fi	AP	of	this	MAZI	Zon
-d,--deactivate              Disconnects the router and restores the initial settings of the Raspberry pi built-in Wi-Fi module
```

### mazi-stat.sh ###
The	mazi-stat.sh	script	enables	the	observation	of	system	activity	data	of	the	Raspberry	Pi	such	as	the	CPU	temperature,	the	CPU	usage,	the	RAM	usage,	the	Storage	usage,	the	Download/Upload	speed	and	the	number	of	users	connected	to	the	Wi-Fi	network.	You	can	also	see	information	about	the	SD	card	such	as	capacity	and	whether	or	not	the	filesystem	has	been	expanded.	Another	functionality	is	the	storage of	these	data	in	a	local	or	remote	database.	In	addition,	you	have	the	ability	to	flush	these	data	from	the	database	in	case	you	do	not	need	them.	

Usage:
```
sudo sh mazi-stat.sh [options]
[options]
-t,--temp                             Displays the CPU core temperature
-u,--users                            Displays the number of connected users
-c,--cpu                              Displays the CPU usage
-r,--ram                              Displays the RAM usage
-s,--storage                          Displays the card storage in use 
--sd                                  Displays information about the SD card
-n,--network                          Displays the Download/Upload speed
-d,--domain                           Set a remote server domain (default is localhost)
--status                              Shows the status of store process
--store [enable,disable,flush]        Controls the status of the storage process

```

### mazi-appstat.sh ###
The	mazi-appstat.sh	script	enables	the	collection	of	statistical	data	from	the	applications	installed	on	the	Raspberry	Pi	and	the	storage	of	these	data	in	a	local	or	remote	database.	In	addition,	you	have	the	ability	to	flush	these	data	from	the	database	in	case	you do	not	need	them.	At	the	moment,	you	can	collect	data	from	the	following	applications,	Guestbook,	Etherpad	and	Framadate.	

Usage:
```
sudo sh mazi-appstat.sh [Application name] [options]

[Application name]
-n,--name                            The name of the application

[options]
--store [enable,disable,flush]       Controls the status of the storage process
--status                             Shows the status of storage process 
-d,--domain                          Sets the server domain to be used for storage (default is localhost)
```

### mazi-mesh.sh ###
With mazi-mesh.sh script you can expand the range of the Wi-Fi Access	Point by creating a mesh network. To be able to create a mesh network, you must have more than one Raspberry	Pi devices. One of these should be chosen as a gateway while the others as nodes. The Raspberry	Pi that was chosen as a gateway is the main node of our topology, as it hosts the Portal of the MAZI toolkit, forwards internet in the mesh network and provides IP to the other nodes and their clients through the DHCP server. The Raspberry	Pi that was chosen as a node is a relay of our mesh network, it redirects its clients to the gateway. Finally, you can restore the initial settings with the portal mode.

Usage:
```
sudo bash mazi-mesh.sh [Mode] [Options]

[Mode]
  gateway                      Operates as a gateway node
  node                         Operates as a relay node
  portal                       Restore to the Portal settings

[gateway Options]
  -i, --interface              Set the interface of the mesh network
  -s, --ssid                   Set the name of the mesh network

[node Options]
  -i, --interface              Set the interface of the mesh network
  -s, --ssid                   Set the name of the mesh network
  -b, --bridgeIface            Set the interface of the Wi-Fi Access Point
```

## License

See the [LICENSE](https://github.com/mazi-project/back-end/blob/master/LICENSE) file for license rights and limitations (MIT).
