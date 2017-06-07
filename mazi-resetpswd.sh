#!/bin/bash  

#This script resets the mazi_admin password of the portal
#
# Usage: mazi-resetpswd.sh 


usage() { echo "This script resets the mazi_admin password of the portal"
          echo ""
          echo "Usage: mazi-password.sh "  1>&2; exit 1; }


if [ $# -gt 0 ];then
   # unknown option
   usage   
fi

sed -i "/:admin_password:/c\  :admin_password: '1234'" /etc/mazi/config.yml
sudo service mazi-portal restart
echo ""
echo "You have just reset your password, please go to the admin page and change your password"
