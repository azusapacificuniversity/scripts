#!/bin/bash

#####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#   CitrixReceiverUpdate.sh -- Installs or updates Citrix Receiver
#
# SYNOPSIS
#   sudo CitrixReceiverUpdate.sh
#
# LICENSE
#   Distributed under the MIT License
#
# EXIT CODES
#   0 - Citrix Receiver is current
#   1 - Citrix Receiver installed successfully
#   2 - Citrix Receiver NOT installed
#   3 - Citrix Receiver update unsuccessful
#   4 - Citrix Receiver is running or was attempted to be installed manually and user deferred install
#   5 - Not an Intel-based Mac
#
# REQUIREMENTS
#   Intell based mac with macOS ver 10.9 or later.
#
####################################################################################################
#
# HISTORY
#
#   Version: 1.2
#
#   - v.1.2 Brian Monroe, 05.31.2016 : Fixed downloads and added regex for version matching
#   - v.1.1 Luie Lugo, 10.18.2016 : Updated for v12.3, also cleaned up download URL handling
#   - v.1.0 Luie Lugo, 09.05.2016 : Updates Citrix Receiver
#
####################################################################################################
# Script to download and install Citrix Receiver.

# Setting variables
receiverProcRunning=0
contactinfo="IMT Support Desk | support@apu.edu | 1-866-APU-Desk | ext 5050"

# Echo function
echoFunc () {
    # Date and Time function for the log file
    fDateTime () { echo $(date +"%a %b %d %T"); }

    # Title for beginning of line in log file
    Title="InstallLatestCitrixReceiver:"

    # Header string function
    fHeader () { echo $(fDateTime) $(hostname) $Title; }

    # Check for the log file
    if [ -e "/Library/Logs/CitrixReceiverUpdateScript.log" ]; then
        echo $(fHeader) "$1" >> "/Library/Logs/CitrixReceiverUpdateScript.log"
    else
        cat "" > "/Library/Logs/CitrixReceiverUpdateScript.log"
        if [ -e "/Library/Logs/CitrixReceiverUpdateScript.log" ]; then
            echo $(fHeader) "$1" >> "/Library/Logs/CitrixReceiverUpdateScript.log"
        else
            echo "Failed to create log file, writing to JAMF log"
            echo $(fHeader) "$1" >> "/var/log/jamf.log"
        fi
    fi

    # Echo out
    echo $(fDateTime) ": $1"
}

# Exit function
exitFunc () {
    case $1 in
        0) exitCode="0 - Citrix Receiver is current! Version: $2";;
        *) exitCode="$1";;
    esac
    echoFunc "Exit code: $exitCode"
    echoFunc "======================== Script Complete ========================"
    exit $1
}

echoFunc "======================== Starting Script ========================"

# Are we on a bad wireless network?
if [[ "$4" != "" ]]
then
    wifiSSID=`/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I |     awk '/ SSID/ {print substr($0, index($0, $2))}'`
    echoFunc "Current Wireless SSID: $wifiSSID"

    badSSIDs=( $4 )
    for (( i = 0; i < "${#badSSIDs[@]}"; i++ ))
    do
        if [[ "$wifiSSID" == "${badSSIDs[i]}" ]]
        then
            echoFunc "Connected to a WiFi network that blocks downloads!"
            exitFunc 6 "${badSSIDs[i]}"
        fi
    done
fi

# Are we running on Intel?
if [ '`/usr/bin/uname -p`'="i386" -o '`/usr/bin/uname -p`'="x86_64" ]; then
    ## Get OS version and adjust for use with the URL string
    OSvers_URL=$( sw_vers -productVersion | sed 's/[.]/_/g' )

    ## Set the User Agent string for use with curl
    userAgent="Mozilla/5.0 (Macintosh; Intel Mac OS X ${OSvers_URL}) AppleWebKit/535.6.2 (KHTML, like Gecko) Version/5.2 Safari/535.6.2"

    # Get the latest version of Receiver available from Citrix's Receiver page.
    latestver=``
    while [ -z "$latestver" ]
    do
        latestver=`curl -s -L https://www.citrix.com/downloads/citrix-receiver/mac/receiver-for-mac-latest.html | grep "<h1>Receiver " | awk '{print $2}'`
    done
    if [[ ${latestver} =~ ^[0-9]+\.[0-9]+$ ]]; then
        # Missing minor version to match the installed version, so we’ll add it here. 
        latestver=${latestver}.0
    fi
    echoFunc "Latest Citrix Receiver Version is: $latestver"
    latestvernorm=`echo ${latestver}`
    
    # Get the version number of the currently-installed Citrix Receiver, if any.
    if [ -e "/Applications/Citrix Receiver.app" ]; then
        currentinstalledapp="Citrix Receiver"
        currentinstalledver=`/usr/bin/defaults read /Applications/Citrix\ Receiver.app/Contents/Info CFBundleShortVersionString`
        echoFunc "Current Receiver installed version is: $currentinstalledver"
        if [ ${latestvernorm} = ${currentinstalledver} ]; then
            exitFunc 0 "${currentinstalledapp} ${currentinstalledver}"
        fi
    else
        currentinstalledapp="None"
        currentinstalledver=“0.0.0”
        echoFunc “Citrix not installed”
    fi

    # Build URL and dmg file name
    CRCurrVersNormalized=$( echo $latestver | sed -e 's/[.]//g' )
    echoFunc "CRCurrVersNormalized: $CRCurrVersNormalized"
    url1="https:"
    url2=`curl -s -L https://www.citrix.com/downloads/citrix-receiver/mac/receiver-for-mac-latest.html#ctx-dl-eula-external | grep dmg? | sed 's/.*rel=.\(.*\)..id=.*/\1/'`
    url=`echo "${url1}${url2}"`
    echoFunc "Latest version of the URL is: $url"
    dmgfile="Citrix_Rec_${CRCurrVersNormalized}.dmg"

    # Compare the two versions, if they are different or Citrix Receiver is not present then download and install the new version.
    if [ "${currentinstalledver}" != "${latestvernorm}" ]; then
        echoFunc "Current Receiver version: ${currentinstalledapp} ${currentinstalledver}"
        echoFunc "Available Receiver version: ${latestver} => ${CRCurrVersNormalized}"
        echoFunc "Downloading newer version."
        curl -s -o /tmp/${dmgfile} ${url}
        case $? in
            0)
                echoFunc "Checking if the file exists after downloading."
                if [ -e "/tmp/${dmgfile}" ]; then
                    receiverFileSize=$(du -k "/tmp/${dmgfile}" | cut -f 1)
                    echoFunc "Downloaded File Size: $receiverFileSize kb"
                else
                    echoFunc "File NOT downloaded!"
                    exitFunc 3 "${currentinstalledapp} ${currentinstalledver}"
                fi
                echoFunc "Mounting installer disk image."
                hdiutil attach /tmp/${dmgfile} -nobrowse -quiet
                echoFunc "Installing..."
                echo "$(date +"%a %b %d %T") Installing Citrix Receiver v$latestver" >> /var/log/CitrixReceiverInstall.log
                # Killing off any running processes
                pkill Citrix Receiver
                installer -pkg "/Volumes/Citrix Receiver/Install Citrix Receiver.pkg" -target / >> /var/log/CitrixReceiverInstall.log # > /dev/null

                sleep 10
                echoFunc "Unmounting installer disk image."
                umount "/Volumes/Citrix Receiver"
                sleep 10
                echoFunc "Deleting disk image."
                rm /tmp/${dmgfile}

                #double check to see if the new version got update
                if [ -e "/Applications/Citrix Receiver.app" ]; then
                    newlyinstalledver=`/usr/bin/defaults read /Applications/Citrix\ Receiver.app/Contents/Info CFBundleShortVersionString`
                    if [ "${latestvernorm}" = "${newlyinstalledver}" ]; then
                        echoFunc "SUCCESS: Citrix Receiver has been updated to version ${newlyinstalledver}, issuing JAMF recon command"
                        jamf recon
                        exitFunc 0 "${currentinstalledapp} ${newlyinstalledver}"
                    else
                        exitFunc 3 "${currentinstalledapp} ${currentinstalledver}"
                    fi
                else
                    exitFunc 3 "${currentinstalledapp} ${currentinstalledver}"
                fi
            ;;
            *)
                echoFunc "Curl function failed on download! Error: $?. Review error codes here: https://curl.haxx.se/libcurl/c/libcurl-errors.html"
            ;;
        esac
    else
        # If Citrix Receiver is up to date already, just log it and exit.
        exitFunc 0 "${currentinstalledapp} ${currentinstalledver}"
    fi
else
    # This script is for Intel Macs only.
    exitFunc 5
fi
