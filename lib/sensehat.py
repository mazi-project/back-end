import os
import time
from sense_hat import SenseHat
import sys
sense = SenseHat()

def usage():
    print 'Usage python sensehat.py [options]'
    print ' '
    print '[options]'
    print '-h , --humidity                 Displays the Humidity '
    print '-t , --temperature              Displays the Temperature'



def get_cpu_temp():
  res = os.popen("vcgencmd measure_temp").readline()
  t = float(res.replace("temp=","").replace("'C\n",""))
  return(t)

# use moving average to smooth readings
def get_smooth(x):
  if not hasattr(get_smooth, "t"):
    get_smooth.t = [x,x,x]
  get_smooth.t[2] = get_smooth.t[1]
  get_smooth.t[1] = get_smooth.t[0]
  get_smooth.t[0] = x
  xs = (get_smooth.t[0]+get_smooth.t[1]+get_smooth.t[2])/3
  return(xs)

def correct_temp():
  for x in range(0, 3):
    t1 = sense.get_temperature_from_humidity()
    t2 = sense.get_temperature_from_pressure()
    t = (t1+t2)/2
    t_cpu = get_cpu_temp()
    # calculates the real temperature compesating CPU heating
    t_corr = t - ((t_cpu-t)/1)
    t_corr = get_smooth(t_corr)
  return(t_corr)


args = len(sys.argv)
if (args == 1):
  print "0"
while ( args > 1):
  args -= 1

  if(sys.argv[args] == "-t" or sys.argv[args] == "--temperature"): 
     print("{0:.1f}".format(correct_temp()))
  #Approximating from Buck's formula Ha = Hm*(2.5-0.029*Tm)
  elif(sys.argv[args] == "-h" or sys.argv[args] == "--humidity"):
    temp = sense.get_temperature()
    humidity = sense.get_humidity()
    calchum=humidity*(2.5-0.029*temp)
    print("{0:.1f}".format(calchum))
  else:
    usage()





