#!/bin/bash

#This script changes the domain of mazi toolkit
#
# Usage: mazi-domain.sh -d <new domain>

###### Initialization ######
hosts="/etc/hosts"
portal_conf="/etc/apache2/sites-available/portal.conf"
index_apache="/var/www/html/index.html"

usage() { echo "This script changes the domain of mazi toolkit"
          echo ""
          echo "Usage: mazi-domain.sh [options]"
          echo "[options]"
          echo "-d,--domain  <new domain>             Set a new Domain of portal page"
          echo "-s,--splash  <application>/<portal>   Set a application or portal as a basic page"  1>&2; exit 1; }

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
  c_domain=$(grep -o -P '(?<=url=http://).*(?=">)' $index_apache)
  sed -i "s/$c_domain/$domain/g" $hosts
  sed -i '/<meta HTTP-EQUIV="REFRESH"/c\          <meta HTTP-EQUIV="REFRESH" content="0; url=http://'$domain'">' $index_apache
  sed -i "s/$c_domain/$domain/g" $portal_conf 
  sudo systemctl daemon-reload
  sudo service apache2 restart
  sudo service dnsmasq restart
fi

if [ $app ];then
   domain=$(grep -o -P '(?<=url=http://).*(?=">)' $index_apache)
   case $app in
    guestbook | etherpad)
    
    [ "$app" = "guestbook" ] && port="8081" || port="9001"
    cat << EOF >  $portal_conf
<VirtualHost *:80>
        Redirect /admin http://local.mazizone.eu/admin
        ServerName $domain
        ProxyPreserveHost On
        ProxyRequests Off
        ProxyPass  /admin !
        ProxyPass / http://localhost:$port/
        ProxyPassReverse / http://localhost:$port/

</VirtualHost>

<VirtualHost *:80>
        ServerName local.mazizone.eu
        ProxyPreserveHost On
        ProxyRequests Off
        ProxyPass / http://localhost:4567/
        ProxyPassReverse / http://localhost:4567/

</VirtualHost>
EOF
    ;;
    framadate| nextcloud | wordpress)    
    
    cat << EOF > $portal_conf
<VirtualHost *:80>
        Redirect /admin http://local.mazizone.eu/admin
        DocumentRoot /var/www/html/$app
        ServerName $domain
</VirtualHost>

<VirtualHost *:80>
        ServerName local.mazizone.eu
        ProxyPreserveHost On
        ProxyRequests Off
        ProxyPass / http://localhost:4567/
        ProxyPassReverse / http://localhost:4567/
</VirtualHost>
EOF
    ;;
    portal)
    cat << EOF > $portal_conf
<VirtualHost *:80>
        ServerName $domain
        ProxyPreserveHost On
        ProxyRequests Off
        ProxyPass / http://localhost:4567/
        ProxyPassReverse / http://localhost:4567/
</VirtualHost>
EOF
    ;;
    *)
    echo "This application is not available "
    ;;
  esac

  sudo systemctl daemon-reload
  sudo service apache2 restart
fi
exit 0
