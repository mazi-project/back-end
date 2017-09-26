#!/bin/bash

#This script changes the domain of mazi toolkit
#
# Usage: mazi-domain.sh -d <new domain>

set -x
usage() { echo "This script changes the domain of mazi toolkit"
          echo ""
          echo "Usage: mazi-domain.sh [options]"
          echo "[options]"          
          echo "-d,--domain  <new domain>   Set a new Domail of portal page"
          echo "-s,--splash  <application>  Set the application as a basic page"  1>&2; exit 1; }

while [ $# -gt 0 ]
do
key="$1"
case $key in
    -d|--domain)
    domain="$2"
    shift # past argument=value
    ;;
    -s|--splash)
    app="$2"
    shift
    ;;
    *)
    # unknown option
    usage
    ;;
esac
shift     #past argument or value
done

if [ $domain ];then
  sed -i '/New Domain/,/EOF/d' /etc/hosts
  echo "#New Domain" >> /etc/hosts
  echo "10.0.0.1        $domain" >> /etc/hosts
  sed -i '/<meta HTTP-EQUIV="REFRESH"/c\          <meta HTTP-EQUIV="REFRESH" content="0; url=http://'$domain'">' /var/www/html/index.html
  sed -i "/ServerName/c\        ServerName $domain" /etc/apache2/sites-available/portal.conf 
  sudo systemctl daemon-reload
  sudo service apache2 restart
  sudo service dnsmasq restart

fi

if [ $app ];then
  case $app in
    guestbook)
    domain="local.mazizone.eu:8081"
    ;;
    etherpad)
    domain="local.mazizone.eu:9001"
    ;;
    framadate)
    domain="local.mazizone.eu/framadate"
    ;;
    nextcloud)
    domain="local.mazizone.eu/nextcloud"
    ;;
    *)
    echo "unavailable application"
    ;;
  esac
  sed -i '/<meta HTTP-EQUIV="REFRESH"/c\          <meta HTTP-EQUIV="REFRESH" content="0; url=http://'$domain'">' /var/www/html/index.html
  sudo systemctl daemon-reload
  sudo service apache2 restart

fi

set +x
