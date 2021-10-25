#!/bin/sh
## Overview ##
# This script downloads and installs the latest version of OBS for macOS.
# 
## History ##
# 7/27/2020 - Brian Monroe - Initial release. 
#
## Variables ##
latestlink='https://github.com/obsproject/obs-studio/releases/latest'
dmgfile="obs-mac-latest.dmg"
logfile="/Library/Logs/Install-Update-OBS-Studio-Script.log"

# Get the URI for the latest version from the latestlink .
downloaduri=`curl -GL $latestlink | grep "href.*dmg" | sed 's/.*href="\(.*\)" rel.*/\1/'`
latestver=`echo $downloaduri | sed 's/.*mac-\(.*\).dmg/\1/'`
/bin/echo "`date`: Latest Version is ${latestver}" >> ${logfile}
# Build the new download link with the URI
downloadurl="https://github.com/${downloaduri}"

# Get the installed version from the local app.
if [ -e "/Applications/OBS.app" ]; then
        installedver=`/usr/bin/defaults read /Applications/OBS.app/Contents/Info CFBundleShortVersionString`
else
        installedver='not installed.'
fi
/bin/echo "`date`: Locally Installed Version is: ${installedver}" >> ${logfile}

# If there's a newer version install it. 
if [ "${latestver}" != "${installedver}" ]; then
        /bin/echo "`date`: Downloading and installing the latest version." >> ${logfile}
        curl -GL -o /tmp/${dmgfile} $downloadurl
        /bin/echo "`date`: Mounting installer disk image." >> ${logfile}
        /usr/bin/hdiutil attach /tmp/${dmgfile} -nobrowse -quiet
        /bin/echo "`date`: Installing..." >> ${logfile}
        ditto -rsrc "/Volumes/OBS/OBS.app" "/Applications/OBS.app"
        /bin/sleep 10
	/bin/echo "`date`: Umounting disk image..." >> ${logfile}
	/usr/bin/hdiutil detach $(/bin/df | grep OBS | awk '{print $1}') -quiet
	/bin/sleep 10
	/bin/echo "`date`: Deleting temp files..." >> ${logfile}
	rm /tmp/${dmgfile}
	/bin/sleep 10
else
        /bin/echo "`date`: This computer already has the latest version" >> ${logfile}
fi
