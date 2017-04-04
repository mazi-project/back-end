#!/bin/bash  

#This script control the available applications
#
# Usage: sudo sh mazi-app.sh  [options] <application>
# 
# [options]
# -a, --action [start,stop,status] <application>    Set the action and name of application
#

#set -x
usage() { echo "Usage: sudo sh mazi-app.sh  [options] <application>" 
          echo " " 
          echo "[options]" 
          echo "-a, --action [start,stop,status] <application>    Set the action and name of application" 1>&2; exit 1; }



path=$(pwd)

######  Parse command line arguments   ######

key="$1"

case $key in
    -a| --action)
     app="$3"
     case $app in
         etherpad)
         sudo service etherpad-lite $2 | grep "Active" |awk '{print $2}'     
         ;;
         mazi-princess)
         sudo service mazi-princess $2 | grep "Active" |awk '{print $2}'
         ;;
         mazi-board)
         sudo service mazi-board $2 | grep "Active" |awk '{print $2}'
         ;;
         *)
         # unknown option
         echo "This application is not available"   
         ;;
    esac
    
    ;;
    *)
       # unknown option
    usage   
    ;;
esac

 
