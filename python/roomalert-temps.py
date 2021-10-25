#!/bin/python3
###############################################################################
#
# AVtech RoomAlert Nagios Centreon Alerts.
#
###############################################################################
#
# NAME: 
#	create-fedora-kiosk.sh
#
# LICENSE:
#	Distributed uner the MIT License.
#
# SYNOPSIS:
#	roomalert-temps.py --help
#
# REQUIREMENTS:
#	Python 3 and AVtech Room Alert equipment.
#
# DESCRIPTION:
#   This is a script to check the temperatures reported by AVtech Room Alert
#   devices. If there are multiple external devices, it will report the highest
#   temp. Intended for use with nagios or Centreon - output will log data with 
#   those systems. Grabs data over http from an unencrytped endpoint. 
#   See --help info for additional instructions. 
#
# EXIT CODES:
#	0 - Success - Tepms are at a normal level. 
#	1 - Warning - Temps exceed the warning level
#	2 - Critical - Temps exceed the critical level. 
#	3 - Failed to access or decode the json data. 
#
# HISTORY:
#	10.25.21 - Brian Monroe
#		Inital Script Release. 
#
###############################################################################
import sys
import requests
import argparse

# Set us up for using runtime arguments by defining them.
parser = argparse.ArgumentParser(description='This pulls the internal and external temps from a Room Alert device using the default getData.json enpoint.')
parser.add_argument('-H', '--host', required=True, dest='host', type=str, help='The Host IP or FQDN of the room alert device to get the json data from.')
parser.add_argument('-iw', '--internal-warning-temp', dest='internalWarnTemp', type=int, default=80, help='The temperature, in Fahrenheit, at which to throw a warning for the internal temp. Defaults to 80')
parser.add_argument('-ew', '--external-warning-temp', dest='externalWarnTemp', type=int, default=80, help='The temperature, in Fahrenheit, at which to throw a warning for the external temp. Defaults to 80')
parser.add_argument('-ic', '--internal-critical-temp', dest='internalCritTemp', type=int, default=85, help='The temperature, in Fahrenheit, at which to throw a critical alert for the internal temp. Defaults to 85')
parser.add_argument('-ec', '--external-critical-temp', dest='externalCritTemp', type=int, default=85, help='The temperature, in Fahrenheit, at which to throw a critical alert for the external temp. Defaults to 85')
runtimeargs = parser.parse_args()
host = runtimeargs.host
internalWarnTemp = runtimeargs.internalWarnTemp
externalWarnTemp = runtimeargs.externalWarnTemp
internalCritTemp = runtimeargs.internalCritTemp
externalCritTemp = runtimeargs.externalCritTemp
url = "http://{}/getData.json".format(host)
externalTemp = float(0)

response = requests.get(url)
try:
        data = response.json()
        name = data['name']
        for sensor in data['sensor']:
                if sensor['label'] == "Internal Sensor":
                        internalTemp = float(sensor['tempf'])
                if sensor['label'] == "External Temp":
                        externalTemp = float(sensor['tempf'])
                if sensor['enabled'] == 1 and sensor['label'] != "Internal Sensor" and float(sensor['tempf']) >= externalTemp:
                        externalTemp = float(sensor['tempf'])

except Exception as e:
        print("Could not decode json values. {}".format(e))
        sys.exit(3)

if internalTemp >= internalCritTemp or externalTemp >= externalCritTemp:
        print("TEMP CRITICAL - {} Internal Temperature = {}/{}, External Temerature = {}/{} | internal_temp={}, external_temp={}".format(name, internalTemp, internalCritTemp, externalTemp, externalCritTemp, internalTemp, externalTemp))
        sys.exit(2)

if internalTemp >= internalWarnTemp or externalTemp >= externalWarnTemp:
        print("TEMP Warning - {} Internal Temperature = {}/{}, External Temerature = {}/{} | internal_temp={}, external_temp={}".format(name, internalTemp,internalWarnTemp, externalTemp, externalWarnTemp, internalTemp, externalTemp))
        sys.exit(1)

print("TEMP OK - {} Internal Temperature = {}, External Temerature = {} | internal_temp={}, external_temp={}".format(name, internalTemp, externalTemp, internalTemp, externalTemp))
