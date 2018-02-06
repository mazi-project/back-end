#!/bin/bash  

#The mazi-app.sh script enables the control of the status of the installed application such as the Etherpad, the Guestbook
#and the Interview-archive. You can start, stop or display the status of the above applications.

#set -x
usage() { echo "Usage: sudo sh mazi-app.sh  [options] <application>" 
          echo " " 
          echo "[options]" 
          echo "-a, --action [start,stop,status] <application>    Controls the status of the installed applications" 1>&2; exit 1; }



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
         sudo service mongodb $2  2>&1 >/dev/null
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

 
