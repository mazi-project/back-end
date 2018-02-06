#!/bin/bash  

#In case you have forgotten your MAZI Portal administrator password, this script enables its recovery. Once you run 
#the mazi-resetpswd.sh, the password change back to the default "1234" and then you can access the MAZI Portal and 
#change it through the first-contact page.


usage() { echo "In case you have forgotten your MAZI Portal administrator password, this script enables its recovery. Once you run" 
          echo "the mazi-resetpswd.sh, the password change back to the default "1234" and then you can access the MAZI Portal and"
          echo "change it through the first-contact page."
          echo ""
          echo "Usage: mazi-resetpswd.sh "  1>&2; exit 1; }


if [ $# -gt 0 ];then
   # unknown option
   usage   
fi

sed -i "/:admin_password:/c\  :admin_password: '1234'" /etc/mazi/config.yml
sudo service mazi-portal restart
echo ""
echo "You have just reset your password to 1234, please go to the admin page and change it"
