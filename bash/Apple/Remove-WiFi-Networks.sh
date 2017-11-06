#!/bin/sh
################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#	Remove-WiFi-Networks.sh - Removes named SSIDs from remembered networks.
#
# LICENSE
#	Distributed under the MIT License
#
# DESCRIPTION
#	This script will remove SSIDs (case sensitive) from the remembered
#	or preferred network list. Useful by running often when in highly
#	saturated areas where it's common for users to accidentally click
#	on the wrong network. 
#
# ADDITIONAL LINKS
#	https://github.com/azusapacificuniversity/scripts
#
# SYNOPSIS
#	sudo Remove-WiFi-Networks.sh
#
################################################################################
#
# HISTORY
#
#   Version: 1.0
#   - Brian Monroe, 18.05.2017
#
################################################################################

# Specify the SSIDs you would like to remove
# Example: SSIDNames=(FBIVan LegitWiFiNetwork PublicWIFI)
SSIDNames=()

# Find the network name (ie en1) for the WiFi or AirPort device. 
wservice=`/usr/sbin/networksetup -listallnetworkservices | grep -Ei '(Wi-Fi|AirPort)'`
device=`/usr/sbin/networksetup -listallhardwareports | awk "/$wservice/,/Ethernet Address/" | awk 'NR==2' | cut -d " " -f 2`

# Remove SSID from remembered networks. 
for SSID in ${SSIDNames[*]}; do
	networksetup -removepreferredwirelessnetwork "$device" ${SSID}
done

exit 0
