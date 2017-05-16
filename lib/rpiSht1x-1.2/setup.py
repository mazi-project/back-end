from distribute_setup import use_setuptools
use_setuptools()
from setuptools import setup, find_packages

setup(
    name = 'rpiSht1x',
    version = '1.2',
    author = 'Luca Nobili',
    author_email = 'lunobiliAT_MARKyahooDOTit',
    packages = find_packages(),
    license = 'LICENSE.txt',
    description = 'Reads Humidity and Temperature from a Sensirion SHT1x sensor.',
    long_description = open('README.txt').read(),
    keywords = "Raspberry Pi RaspberryPi SHT15 SHT11 SHT1x Humidity Temperature GPIO",
    install_requires = "RPi.GPIO",
)