# MAZI back-end
This is the back-end scripts of the MAZI toolkit. You can clone this repository into a [MAZI zone image] (http://nitlab.inf.uth.gr/mazi-img/) and configure accordingly your MAZI zone.

## wifiap.sh
The *wifiap.sh* script creates a Wi-Fi Access Point according to the configuration you define. The script modifies the file */etc/hostapd/hostapd.conf* and then restarts the hostapd service.

Usage:
*sudo sh wifiap.sh  [options]*

[options]

-s,--ssid                                The name of the WiFi Access Point

-c,--channel                             The channel to use

-w,--wpa                                 Set off/OFF if you want to turn off wireless network security

-p,--password                            The password of the Access Point


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

The *mazi-stat.sh* script dispalys the total online users of the MAZI zone WIFI network.

Usage:
```

sudo sh mazi-stat.sh -u 

## License

See the [LICENSE] (https://github.com/mazi-project/back-end/blob/master/LICENSE) file for license rights and limitations (MIT).
