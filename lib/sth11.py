#!/usr/bin/python

from sht1x.Sht1x import Sht1x as SHT1x
import sys
dataPin = 35
clkPin = 33
sht1x = SHT1x(dataPin, clkPin, SHT1x.GPIO_BOARD)


def usage():
    print 'Usage python sth11.py [options]'
    print ' '
    print '[options]'
    print '-h , --humidity                 Displays the Humidity '
    print '-t , --temperature              Displays the Temperature'    


   
args = len(sys.argv)
if (args == 1):
  print "0"
while ( args > 1):
  args -= 1   

  if(sys.argv[args] == "-h" or sys.argv[args] == "--humidity"):
    humidity = sht1x.read_humidity()  
    print("{0:.2f}".format(humidity))
  elif(sys.argv[args] == "-t" or sys.argv[args] == "--temperature"):
    temperature = sht1x.read_temperature_C()
    print("{0:.2f}".format(temperature))
  else:
    usage()

 


