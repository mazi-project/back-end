# MAZI back-end
This is the back-end scripts of the MAZI toolkit

### wifiap.sh
The *wifiap.sh* script creates a Wi-Fi Access Point according to the configuration we define. The script modifies the file */etc/hostapd/hostapd.conf* and then restarts the hostapd service.

Usage:
*sudo sh wifiap.sh  [options]*

[options]
-s,--ssid                                The name of the WiFi Access Point
-c,--channel                             The channel to use
-w,--wpa                                 Set off/OFF if you want to turn off wireless network security
-p,--password                            The password of the Access Point

Examples
--------
Set up a Wi-Fi Access Point
```

sudo sh wifiap.sh  -s mazizone -c 6 -p mazizone

```

change the name of the Access Point
```

sudo sh wifiap.sh -s John

```

**Password**
Its length should be more than 8.


### internet.sh

Usage:
```

sudo sh internet.sh -m <offline/dual/restricted>

```

offline: the local WiFi network is not connected to the Internet
dual: the local WiFi network is connected to the Internet
restricted: some of the clients have access to the Internet
