#!/bin/sh
################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#	Install-Update-Firefox.sh -- Installs Latest Version of Firefox
#
# REQUIREMENTS
#	Intell based macOS ver 10.9 or later. 
#
# SYNOPSIS
#	sudo Install-Update-Firefox.sh
#
# ADDITIONAL LINKS
#	https://github.com/azusapacificuniversity/scripts
#
# LICENSE
#	Distributed under the MIT License.
#
################################################################################
#
# HISTORY
#
#   Version: 1.1
#	- Brian Monroe, 18.05.2017
#   	*General code clean up to install latest version always and remove 
#	language options. 
#   Version: 1.0
#	- Joe Farage, 18.03.2015
#
################################################################################
# Script to download and install Firefox.
# Only works on Intel systems.


lang="en-US"
dmgfile="mozillafirefox.dmg"
logfile="/Library/Logs/FirefoxInstallScript.log"

# Are we running on Intel?
if [ '`/usr/bin/uname -p`'="i386" -o '`/usr/bin/uname -p`'="x86_64" ]; then
	# Get OS version and adjust for use with the URL string
	OSvers_URL=$( sw_vers -productVersion | sed 's/[.]/_/g' )
	
	# Find the Current Installed Version
	if [ -e "/Applications/Firefox.app" ]; then
		installedver=`/usr/bin/defaults read /Applications/Firefox.app/Contents/Info CFBundleShortVersionString`
	else
		installedver='none'
	fi
	/bin/echo "`date`: Installed Version is ${installedver}" >> ${logfile}

	# Get the latest version available from Firefox page.
	/usr/bin/curl -O FireFox*.dmg "https://download.mozilla.org/?product=firefox-latest&os=osx&lang=en-US" > /tmp/firefox.txt
	latestver=$(grep dmg /tmp/firefox.txt | sed 's/.*releases.\(.*\).mac.*/\1/')
	rm /tmp/firefox.txt
	/bin/echo "`date`: Latest Version is ${latestver}" >> ${logfile}

	# Download the latest version and mount the dmg. 
	if [ "${installedver}" != "${latestver}" ]; then
		/bin/echo "`date`: Downloading and installing the latest version." >> ${logfile}
		/usr/bin/curl -GL -o /tmp/${dmgfile} -d "product=firefox-latest&os=osx&lang=en-US" https://download.mozilla.org/
		/bin/echo "`date`: Mounting installer disk image." >> ${logfile}
		/usr/bin/hdiutil attach /tmp/${dmgfile} -nobrowse -quiet
		/bin/echo "`date`: Installing..." >> ${logfile}
		ditto -rsrc "/Volumes/Firefox/Firefox.app" "/Applications/Firefox.app"
		# Clean up tasks.
		/bin/sleep 10
		/bin/echo "`date`: Unmounting installer disk image." >> ${logfile}
		/usr/bin/hdiutil detach $(/bin/df | /usr/bin/grep Firefox | awk '{print $1}') -quiet
		/bin/sleep 10
		/bin/echo "`date`: Deleting disk image." >> ${logfile}
		/bin/rm /tmp/${dmgfile}
	else
		/bin/echo "`date`: Firefox already up to date. Nothing to do." >> ${logfile}
	fi
else
	/bin/echo "`date`: ERROR: This script is for Intel Macs only." >> ${logfile}
fi

exit 0
