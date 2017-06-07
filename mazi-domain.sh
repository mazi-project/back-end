#!/bin/bash

#This script changes the domain of 
#
# Usage: mazi-resetpswd.sh


usage() { echo "This script changes the domain of mazi toolkit"
          echo ""
          echo "Usage: mazi-domain.sh -d <new domain> "  1>&2; exit 1; }

if [ $# -gt 0 ];then
   # unknown option
   usage
fi


sed -i "//c\  :admin_password: '1234'" /etc/mazi/config.yml

