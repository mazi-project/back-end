'''
Created on Oct 1, 2012

@author: lnobili
'''

BOARD = 0
OUT = 0
IN = 0
PUD_UP = 0
HIGH = 1
LOW = 0

def setmode(something):
    pass

def setup(something1, something2, pull_up_down = 0):
    pass

def input(something):
    return LOW

def output(pinName, value):
    if value == HIGH:
        print("{}: On".format(pinName))
    else:
        print("{}: Off".format(pinName))

def cleanup():
    pass