#!/bin/bash

###### Initialization ######
path="/var/www/html/mazi-board/src/www/js/templates/"



usage() { echo "Usage: sudo sh guestbook.sh  [options]" 
          echo " " 
          echo "[options]"
          echo "-b,--background      Modify the background image" 
          echo "-m,--message         Modify the central message"
          echo "-l,--logo            Modify the logo " 
          echo "-c,--current         Dispalys the current configuration" 1>&2; exit 1; 
}

current_conf() {
  current_m=$(grep -o -P '(?<=class="submission-headline"><h1>).*(?=<span class="blinking-cursor">)' $path/submission_input_tmpl.html)
  current_logo=$(grep -o -P '(?<=class="logo"><img src="images/).*(?=">)' $path/header_tmpl.html)
  current_image=$(grep -o -P '(?<=class="header-image column"><img src="images/).*(?="></div>)' $path/header_tmpl.html)
  echo "message: $current_m"
  echo "logo: $current_logo"
  echo "background: $current_image"
}

message(){
 current_m=$(current_conf | grep "message" | awk '{print $NF}')
 sed -i "s/$current_m/$message/g" $path/submission_input_tmpl.html
}

logo(){
 current_logo=$(current_conf | grep "logo" | awk '{print $NF}')
 sed -i "s/$current_logo/$logo/g" $path/header_tmpl.html
}

background(){
 current_image=$(current_conf | grep "background" | awk '{print $NF}')
 sed -i "s/$current_image/$image/g" $path/header_tmpl.html
}



while [ $# -gt 0 ]
do
  key="$1"
 
  case $key in
      -b|--background)
      image="$2"
      background
      shift  
      ;;
      -m|--message)
      message="$2"
      message
      shift
      ;; 
      -l|--logo)
      logo="$2"
      logo
      shift
      ;;
      -c|--current)
      current_conf     
      ;;
      *)
      # unknown option
      usage   
      ;;
  esac
  shift #past argument or value
done

