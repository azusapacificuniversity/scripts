#!/bin/sh
################################################################################
#
#  NAME:
#    Install-Google-Backup-And-Sync.sh
#
#  SYNOPSIS:
#    sudo .\Install-Google-Backup-And-Sync.sh
#
#  DESCRIPTION:
#    Downloads the latest version of Google Drive Backup And Sync and installs 
#    it. This scrip also checks to see if Google Drive is installed. If so, the
#    script launches a window that notifies the user that the program is being
#    removed, but any data that is there will remain in place and encourages the
#    user to move the data, or delete it. There is a variable to set with your
#    support information. This script also creates a default settings file that
#    adds the Desktop, Documents, Music, Movies, Pictures, and Public folders as
#    defaults for backup and sync. You can easily edit the varibale section 
#    "settingsContent" to alter any requested changes to those default settings.
#    Drive Sync is turned off for concurrent installation with File Stream.
#    Take note that this script does not change the default for all users, but
#    only the user that is currently logged in. Nor will this change the sync
#    settings of a user that is already signed in. There is a section that can
#    be uncommented to display a message if depricated versions of Google Drive
#    are found. 
#
#  REQUIREMENTS
#    Intel based Apple computers running macOS ver 10.9 or later. 
#
#  LICENSE
#    Distributed Under the MIT License.
#
#  ADDITIONAL LINKS
#    https://github.com/azusapacificuniversity/scripts
#
################################################################################
#
#  HISTORY:
#    Version 1.0
#      Brian Monroe 19.10.2017
#
################################################################################


# Set some variables
SupportContactInfo="your System Administrator"
url="https://dl.google.com/drive/InstallBackupAndSync.dmg"
dmgfile="InstallBackupAndSync.dmg"
volname="Install Backup and Sync from Google"
user=`ls -l /dev/console | awk '{print $3}'`
logfile="/Library/Logs/GoogleBackupAndSync.log"
settingsFile="/Users/${user}/Library/Application Support/Google/Drive/user_default/user_setup.config"

settingsContent="[Computers]
desktop_enabled: True
documents_enabled: True
pictures_enabled: True
folders: /Users/${user}/Music, /Users/${user}/Movies, /Users/${user}/Public
high_quality_enabled: False
always_show_in_photos: False
usb_sync_enabled: False

[MyDrive]
folder: path/to/google_drive
my_drive_enabled: False

[Settings]
autolaunch: True

[Network]
download_bandwidth: 150
upload_bandwidth: 200
use_direct_connection: False"

# Say What We're Doing
/bin/echo "`date`: Installing latest version of Backup And Sync for $user..." >> ${logfile}

# Create default install settings for Backup And Sync. 
/bin/echo "`date`: Verify settings path exists." >> ${logfile}
mkdir -p "$(dirname "$settingsFile")"
/bin/echo "`date`: Creating or clearing the config file." >> ${logfile}
> ${settingsFile}
/bin/echo "`date`: Writing settings." >> ${logfile}
/usr/bin/printf  "${settingsContent}" >> ${settingsFile}

# Own that stuff so the user can read it. 
/bin/echo "`date`: Checking ownership." >> ${logfile}
chown -Rf $user /Users/$user/Library/Application\ Support/Google

# Check for Deprecated versions of Drive
if [ -d /Applications/Google\ Drive.app/ ]; then
  /bin/echo "`date`: Found depricated version of Google Drive. Stopping Drive service." >> ${logfile}
  /usr/bin/osascript -e 'tell application "Google Drive" to quit'
  /bin/echo "`date`: Deleting Google Drive Application." >> ${logfile}
  rm -Rf /Applications/Google\ Drive.app/
  
  # This next section should be uncommented if you are using JAMF and have jamfHelper available
#  /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper  -title "Google Drive Version Found" -windowType hud -description "Google Drive Version Found" -description "While installing Google Drive File Stream we found an older version of Google Drive. Since they are not compatible, we removed the older version. However, you still have data stored in your home folder under Google Drive. These files will no longer be synced, so you should either move them or delete them. If you have any addional questions please reach out to ${SupportContactInfo}." &
fi

# Download All The Things!
/bin/echo "`date`: Downloading Backup And Sync disk image." >> ${logfile}
/usr/bin/curl -k -o /tmp/$dmgfile $url
/bin/echo "`date`: Mounting disk image." >> ${logfile}
/usr/bin/hdiutil attach /tmp/$dmgfile -nobrowse -quiet

# Install the Application
if [ -d /Applications/Backup\ and\ Sync.app/ ]; then
  /bin/echo "`date`: Found App already installed: Shutting down service." >> ${logfile}
  /usr/bin/osascript -e 'tell application "Backup and Sync" to quit'
fi
/bin/echo "`date`: Installing..." >> ${logfile}
ditto -rsrc "/Volumes/${volname}/Backup and Sync.app" "/Applications/Backup and Sync.app"
/bin/sleep 3

# Cleanup Tasks
/bin/echo "`date`: Unmounting installer disk image." >> ${logfile}
/usr/bin/hdiutil detach $(/bin/df | /usr/bin/grep "${volname}" | awk '{print $1}') -quiet
/bin/echo "`date`: Removing the installer disk image." >> ${logfile}
rm -fv /tmp/$dmgfile
/bin/sleep 3
/bin/echo "`date`: Launching app." >> ${logfile}
open -a /Applications/Backup\ and\ Sync.app/
/bin/echo "`date`: Finished." >> ${logfile}

exit 0
