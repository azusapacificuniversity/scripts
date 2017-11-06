#!/bin/sh	
################################################################################
# ABOUT THIS PROGRAM
#
# NAME
#	Install-SAManage-Agent-for-Mac.sh
#
# DESCRIPTION
#	This script checks to see if the depricated versions of the agent are 
#	installed and removes them. It then downloads the latest version from 
#	the website and installs it silently.
#
# LICENSE
#	Distributed under the MIT License
#
# REQUIREMENTS
#	macOS version 10.9 or later. A samanage account is required, and you
#	will need to edit the first variable with your account information.
#
# ADDITIONAL LINKS
#	https://github.com/azusapacificuniversity/scripts
#	http://www.samanage.com
#
# SYNOPSIS
#	sudo Install-SAManage-Agent-for-Mac.sh
#
################################################################################
# HISTORY
#
#   Version: 1.0
#   - Brian Monroe, 22.05.2017
#
################################################################################
# Set some variables
# Replace <AccountName> with the name of your samanage account on the line below
samanageAccount="<AccountNamed>"
logfile="/Library/Logs/SAManageAgentInstall.log"

/bin/echo "`date`: Starting install script..." >> ${logfile}

# Uninstall current SAManage agent
if [ -f  /Applications/Samanage\ Agent.app/Contents/Resources/uninstaller.sh ]; then
  /bin/echo "`date`: Found an older version: uninstalling..." >> ${logfile}
  /Applications/Samanage\ Agent.app/Contents/Resources/uninstaller.sh
  /bin/echo "`date`: finished." >> ${logfile}
fi

# Change working directory to /tmp
cd /tmp

# Download SAManage Mac agent software
/bin/echo "`date`: Downloading latest version from samanage.com." >> ${logfile}
curl -O http://cdn.samanage.com/download/Mac+Agent/SAManage-Agent-for-Mac.dmg

# Mount the SAManage-Agent-for-Mac.dmg disk image as /tmp/SAManage-Mac-Agent
/bin/echo "`date`: Download finshed. Mounting disk image. " >> ${logfile}
hdiutil attach SAManage-Agent-for-Mac.dmg -nobrowse -noverify -noautoopen

# Set the SAManage account name for the installer. 
/bin/echo "`date`: Adding ${samanageAccount} as the account to the installer." >> ${logfile}
/bin/echo ${samanageAccount} > /tmp/samanage

################################################################################
# Uncomment the command below if you do not wish the Samanage agent to collect 
# software information
#
# /bin/echo "nosoft=1" > /tmp/samanage_no_soft
#
################################################################################

# Install the SAManage Mac agent
/bin/echo "`date`: Installing SAManage..." >> ${logfile}
installer -dumplog -verbose -pkg /Volumes/Samanage-Mac-Agent-*/Samanage-Mac-Agent-*.pkg -target "/"

# Clean-up
# Unmount the SAManage-Agent-for-Mac.dmg disk image from /Volumes
/bin/echo "`date`: Done. Performing cleanup tasks." >> ${logfile}
hdiutil eject -force /Volumes/Samanage-Mac-Agent-*

# Remove /tmp/samanage
rm /tmp/samanage

if [ -f  /tmp/samanage_no_soft ]; then
  rm /tmp/samanage_no_soft
fi

# Remove the SAManage-Agent-for-Mac.dmg disk image from /tmp
rm /tmp/SAManage-Agent-for-Mac.dmg
/bin/echo "`date`: Installation complete." >> ${logfile}

exit 0
