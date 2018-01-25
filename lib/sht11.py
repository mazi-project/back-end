#!/usr/bin/pytho
import sys
import warnings

def help_message():
    print ' '
    print 'sht11'
    print '  --help                          Displays this usage message '
    print '  --detect                        Displays if the sensor is connected on Raspberry Pi'
    print '  -h , --humidity                 Displays the Humidity '
    print '  -t , --temperature              Displays the Temperature'    

def sht11( sensor ):
 try:
  warnings.filterwarnings("ignore")
  from sht1x.Sht1x import Sht1x as SHT1x
  dataPin = 5
  clkPin = 3
  sht1x = SHT1x(dataPin, clkPin, SHT1x.GPIO_BOARD)

  if (sensor == "humidity"):
    mesurement = sht1x.read_humidity()
  elif (sensor == "temperature"): 
    mesurement = sht1x.read_temperature_C()

  return mesurement
 except:
  return "false"  
 
def detect():
   var = sht11("temperature")
   if (type(var) == int or type(var) == float):
     print 'sht11'

if __name__ == '__main__':

   args = len(sys.argv)
   while ( args > 1):
     args -= 1

     if(sys.argv[args] == "--help"):
        help_message()
     elif(sys.argv[args] == "--detect"):
        detect()
     elif(sys.argv[args] == "-t" or sys.argv[args] == "--temperature"):
       temperature = sht11("temperature")
       print ("temperature %.1f" % temperature)
     elif(sys.argv[args] == "-h" or sys.argv[args] == "--humidity"):
       humidity = sht11("humidity")
       print ("humidity %.1f" % humidity)

