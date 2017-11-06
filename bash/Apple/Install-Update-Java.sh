#!/bin/sh
################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#	Install-Update-Java.sh -- Installs the latest Oracle Java version
#
# SYNOPSIS
#	sudo ./Install-Update-Java.sh
#
# REQUIREMENTS
#	macOS version 10.7 or later. 
#
# DESCRIPTION
#	Checks the version of Java that is currently installed, if any, and 
#	installs a newer version if it's available. 
#
# LICENSE
#	Distributed under the MIT License
#
# ADDITIONAL LINKS
#	https://github.com/azusapacificuniversity/scripts
#
################################################################################
#
# HISTORY
#
#   Version: 1.0 - 06.06.2017
#
################################################################################
# Determine OS version
osvers=$(sw_vers -productVersion | awk -F. '{print $2}')

# Download the jsp file for extrating version and url for the dmg
oracle_jsp=/tmp/oracle_manual.jsp
curl -L http://www.java.com/en/download/manual.jsp > $oracle_jsp

# check if newer version exists
plugin="/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Info.plist"
if [ -f "$plugin" ]
then
    currentver=`/usr/bin/defaults read "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Info.plist" CFBundleShortVersionString`
    echo " Current version is $currentver"
    currentvermain=`echo "$currentver" | awk '{print$2}'`
    echo "Installed main version is $currentvermain"
    currentvermin=`echo "$currentver" | awk '{print$4}'`
    echo "Installed minor version is $currentvermin"
    onlineversionmain=`cat < $oracle_jsp | grep "Recommended Version" | awk '{ print $4}'`
    echo "Online main: $onlineversionmain"
    onlineversionmin=`cat < $oracle_jsp | grep "Recommended Version" | awk '{ print $6}' | awk -F "<" '{ print $1}'`
    echo "Online minor: $onlineversionmin"
    if [ -z "${currentvermain}" ] || [ "${onlineversionmain}" -gt "${currentvermain}" ]
    then
        echo "Let's install Java! Main online version is higher than installed version."
        installjava=1
    fi
    if [ "${onlineversionmain}" = "${currentvermain}" ] && [ "${onlineversionmin}" -gt "${currentvermin}" ]
    then
        echo "Let's install Java! Main online version is equal than installed version, but minor version is higher."
        installjava=1
    fi
    if [ "${onlineversionmain}" = "${currentvermain}" ] && [ "${onlineversionmin}" = "${currentvermin}" ]
    then
        echo "Java is up-to-date!"
    fi
else
    echo "No java installed, let's install"
    installjava=1
fi


# Find Download URL
fileURL=`grep -m1 "Download Java for Mac OS X" $oracle_jsp | sed 's/.*ref=.\(.*\)..oncl.*/\1/'`

# Specify name of downloaded disk image

java_eight_dmg="/tmp/java_eight.dmg"

if [[ ${osvers} -lt 7 ]]; then
  echo "Oracle Java 8 is not available for Mac OS X 10.6.8 or earlier."
  exit 0
fi

if [ "$installjava" = 1 ]
then
    echo "Start installing Java"
    if [[ ${osvers} -ge 7 ]]; then

        # Download the latest Oracle Java 8 software disk image

        /usr/bin/curl --retry 3 -Lo "$java_eight_dmg" "$fileURL"

        # Specify a /tmp/java_eight.XXXX mountpoint for the disk image

        TMPMOUNT=`/usr/bin/mktemp -d /Volumes/java_eight.XXXX`

        # Mount the latest Oracle Java disk image to /tmp/java_eight.XXXX mountpoint

        hdiutil attach "$java_eight_dmg" -mountpoint "$TMPMOUNT" -nobrowse -noverify -noautoopen

        # Install Oracle Java 8 from the installer package.

        if [[ -e "$(/usr/bin/find $TMPMOUNT -name *Java*.pkg)" ]]; then    
            pkg_path=`/usr/bin/find $TMPMOUNT -name *Java*.pkg`
        elif [[ -e "$(/usr/bin/find $TMPMOUNT -name *Java*.mpkg)" ]]; then    
            pkg_path=`/usr/bin/find $TMPMOUNT -name *Java*.mpkg`
        fi

        # Before installation, the installer's developer certificate is checked 

        if [[ "${pkg_path}" != "" ]]; then
                echo "installing Java from ${pkg_path}..."
                /usr/sbin/installer -dumplog -verbose -pkg "${pkg_path}" -target "/" > /dev/null 2>&1
        fi

        # Clean-up

        # Unmount the disk image from /tmp/java_eight.XXXX

        /usr/bin/hdiutil detach -force "$TMPMOUNT"

        # Remove the /tmp/java_eight.XXXX mountpoint

        /bin/rm -rf "$TMPMOUNT"

        # Remove the downloaded disk image

        /bin/rm -rf "$java_eight_dmg"

        # Remove xml file
        /bin/rm -rf /tmp/au-1.8.0_20.xml
    fi
fi

# Remove the jsp file
rm $oracle_jsp

exit 0
