import os
import time
import sys
#from pathlib2 import Path

### initialization
magnetometer = False
gyroscope = False
accelerometer = False
mv_sensors=False


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


def help_message():
    print(' ')
    print('sensehat')
    print('  --help                          Displays this usage message')
    print('  --detect                        Displays if the sensor is connected on the Raspberry Pi')
    print('  -h , --humidity                 Displays the Humidity ')
    print('  -t , --temperature              Displays the Temperature')
    print('  -p , --pressure                 Displays the current pressure in Millibars.')
    print('  -m , --magnetometer             Displays the direction of North')
    print('  -g , --gyroscope                Displays a dictionary object indexed by the strings x, y and z.')
    print('                                  The values are Floats representing the angle of the axis in degrees')
    print('  -ac , --accelerometer           Displays a dictionary object indexed by the strings x, y and z.')
    print('                                  The values are Floats representing the acceleration intensity of the axis in Gs')



def detect():
  if os.path.exists("/proc/device-tree/hat/product"):
    print 'sensehat'



def sensehat(sensor):
  from sense_hat import SenseHat
  sense = SenseHat()
 
  if(sensor == "mv_sensors"):
    while True:
      if(magnetometer == True):
        sense.set_imu_config(True, False, False)
        north = sense.get_compass()
        print("direction {0:.1f}".format(north))
      if(gyroscope == True):
        sense.set_imu_config(False, True, False)
        gyro_only = sense.get_gyroscope()
        print("pitch: {pitch}".format(**sense.gyro))
        print("yaw: {yaw}".format(**sense.gyro))
        print("roll: {roll}".format(**sense.gyro))
      if(accelerometer == True):
        sense.set_imu_config(False, False, True)
        raw = sense.get_accelerometer_raw()
        print("ac_x: {x}".format(**raw))
        print("ac_y: {y}".format(**raw))
        print("ac_z: {z}".format(**raw))
   
  elif (sensor == "temperature"):
      for x in range(0, 3):
        t1 = sense.get_temperature_from_humidity()
        t2 = sense.get_temperature_from_pressure()
        t = (t1+t2)/2
        t_cpu = get_cpu_temp()
        # calculates the real temperature compesating CPU heating
        t_corr = t - ((t_cpu-t)/1.6)
        t_corr = get_smooth(t_corr)
        mesurement = t_corr
  elif (sensor == "humidity"):
      #Approximating from Buck's formula Ha = Hm*(2.5-0.029*Tm)
      temp = sense.get_temperature()
      humidity = sense.get_humidity()
      calchum = humidity*(2.5-0.029*temp)
      mesurement = calchum 
  elif (sensor == "pressure"):
      mesurement = sense.get_pressure()
  return mesurement


if __name__ == '__main__':

  args = len(sys.argv)
  while ( args > 1):
    args -= 1

    if(sys.argv[args] == "-t" or sys.argv[args] == "--temperature"): 
       temperature = sensehat("temperature")
       print("temperature {0:.1f}".format(temperature))
    elif(sys.argv[args] == "-h" or sys.argv[args] == "--humidity"):
       humidity = sensehat("humidity")
       print("humidity {0:.1f}".format(humidity))
    elif(sys.argv[args] == "-p" or sys.argv[args] == "--pressure"):
       pressure = sensehat("pressure")
       print("pressure {0:.1f}".format(pressure))
    elif(sys.argv[args] == "-m" or sys.argv[args] == "--magnetometer"):
       magnetometer = True
       mv_sensors = True
    elif(sys.argv[args] == "-g" or sys.argv[args] == "--gyroscope"):
       gyroscope = True
       mv_sensors = True  
    elif(sys.argv[args] == "-ac" or sys.argv[args] == "--accelerometer"):
       accelerometer = True
       mv_sensors = True
    elif(sys.argv[args] == "--help"):
       help_message()
    elif(sys.argv[args] == "--detect"):
       detect()

  if (mv_sensors):
      sensehat("mv_sensors")  
