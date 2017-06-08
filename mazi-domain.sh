#!/bin/bash

#This script changes the domain of mazi toolkit
#
# Usage: mazi-domain.sh -d <new domain>


usage() { echo "This script changes the domain of mazi toolkit"
          echo ""
          echo "Usage: mazi-domain.sh -d <new domain> "  1>&2; exit 1; }

while [ $# -gt 0 ]
do
key="$1"
case $key in
    -d)
    domain="$2"
    shift # past argument=value
    ;;
    *)
    # unknown option
    usage
    ;;
esac
shift     #past argument or value
done


sed -i '/New Domain/,/EOF/d' /etc/hosts
echo "New Domain" >> /etc/hosts
echo "10.0.0.1        $domain" >> /etc/hosts
sed -i '/<meta HTTP-EQUIV="REFRESH"/c\          <meta HTTP-EQUIV="REFRESH" content="0; url=http://'$domain'">' /var/www/html/index.html
sed -i "/ServerName/c\        ServerName $domain" /etc/apache2/sites-available/portal.conf 
sudo systemctl daemon-reload
sudo service apache2 restart
