#!/bin/sh
################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#   Install-Update-Adobe-Flash.sh -- Installs or updates Adobe Flash Player
#
# REQUIREMENTS
#   Requires macOS ver 10.9 or later
#
# LICENSE
#   MIT
#
# DESCRIPTION
#   This script checks the latest version of Flash available and installs it if 
#   is newer than the version that is currently installed, or if no version is
#   found on the computer.
#
# ADDITIONAL LINKS
#   https://github.com/azusapacificuniversity/scripts
#
################################################################################
#   
# CHANGELOG
#   Ver 1.0 - Brian Monroe 2017-06-08
#
################################################################################

# Set some variables
dmgfile="/tmp/flash.dmg"
volname="Flash"
logfile="/Library/Logs/jamf.log"

echo "Gathering Info"
# Get the lastest stable release number
latestver=`curl --connect-timeout 8 --max-time 8 -sf "http://fpdownload2.macromedia.com/get/flashplayer/update/current/xml/version_en_mac_pl.xml" 2>/dev/null | xmllint --format - 2>/dev/null | awk -F'"' '/<update version/{print $2}' | sed 's/,/./g'`
shortver=${latestver:0:2}
url=https://fpdownload.adobe.com/get/flashplayer/pdc/${latestver}/install_flash_player_osx.dmg

# Get the version number of the currently-installed Flash Player, if any.
if [ -f "/Library/Internet Plug-Ins/Flash Player.plugin/Contents/version" ]; then
    currentinstalledver=`/usr/bin/defaults read "/Library/Internet Plug-Ins/Flash Player.plugin/Contents/version" CFBundleShortVersionString`
else
    currentinstalledver="none"
fi

# Compare the two versions, if they are different of Flash is not present then download and install the new version.
if [ "${currentinstalledver}" != "${latestver}" ]; then
    echo "Downloading latest version..."
    /bin/echo "`date`: Current Flash version: ${currentinstalledver}" >> ${logfile}
    /bin/echo "`date`: Available Flash version: ${latestver}" >> ${logfile}
    /bin/echo "`date`: Downloading newer version." >> ${logfile}
    /usr/bin/curl -s -o $dmgfile $url
    /bin/echo "`date`: Mounting installer disk image." >> ${logfile}
    /usr/bin/hdiutil attach $dmgfile -nobrowse -quiet
    echo "Installing..."
    /bin/echo "`date`: Installing..." >> ${logfile}
    /usr/sbin/installer -pkg /Volumes/Flash\ Player/Install\ Adobe\ Flash\ Player.app/Contents/Resources/Adobe\ Flash\ Player.pkg -target / > /dev/null
    /bin/echo "`date`: Done." >> ${logfile}
    /bin/sleep 10
    echo "Performing cleanup..."
    /bin/echo "`date`: Unmounting installer disk image..." >> ${logfile}
    /usr/bin/hdiutil detach $(/bin/df | /usr/bin/grep ${volname} | awk '{print $1}') -quiet
    /bin/sleep 10
    /bin/echo "`date`: Deleting disk image." >> ${logfile}
    /bin/rm $dmgfile
    newlyinstalledver=`/usr/bin/defaults read "/Library/Internet Plug-Ins/Flash Player.plugin/Contents/version" CFBundleShortVersionString`
    if [ "${latestver}" = "${newlyinstalledver}" ]; then
        /bin/echo "`date`: SUCCESS: Flash has been updated to version ${newlyinstalledver}"
        /bin/echo "`date`: SUCCESS: Flash has been updated to version ${newlyinstalledver}" >> ${logfile}
    else
        /bin/echo "`date`: ERROR: Flash update unsuccessful, version remains at ${currentinstalledver}." >> ${logfile}
        /bin/echo "--" >> ${logfile}
    fi

# If Flash is up to date already, just log it and exit.       
else
    /bin/echo "`date`: Flash is already up to date, running ${currentinstalledver}."
    /bin/echo "`date`: Flash is already up to date, running ${currentinstalledver}." >> ${logfile}
    /bin/echo "--" >> ${logfile}
fi

exit 0
