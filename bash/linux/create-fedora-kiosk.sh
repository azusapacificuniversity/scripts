#!/bin/bash
###############################################################################
#
# Create Fedora Kiosk
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
#	sudo ./create-fedora-kiosk.sh
#
# REQUIREMENTS:
#	OS: Fedora 25 or newer.
#	Arch: i386 or x86_64
#	Requires active network conenction.
#
# DESCRIPTION:
#	This script converts a Fedora install into a chromium (webkit) kiosk. 
#	You may choose to set variables that also install the version of Citrix
#	Receiver. Setting the start page to your webstore will effectively 
#	create a thin client image for Citrix Receiver. A local user, called
#	kiosk, will be created and set to auto login. The script also edits
#	/usr/share/misc/magic to add an enry for .ica files so file reports
#	them properly as mime:application/x-ica and not text/plain. Failure
#	to do so results in the an infinate number of tabs being opened by
#	chromium. 
#
# EXIT CODES:
#	0 - Success
#	1 - Failed - Needs to be run as root.
#	2 - Network Failure - Are you online?
#	3 - Failed to download/install Chromium.
#	4 - Failed to download/install Citrix Receiver.
#	5 - Failed to create log file.
#	6 - Failed - Not running supported OS. 
#
# HISTORY:
#	10.11.2017 - Brian Monroe
#		Inital Script Release. 
#
###############################################################################

# Set Some Variables:
log=/var/log/create-kiosk.log
user=$( whoami )
releaseinfo=$( grep -m1 release /etc/system-release )
elver=$( cat /etc/fedora-release | sed 's/.*release \([0-9][0-9]\).*/\1/' )
cpu=$( uname -i )

# This is website that the script verifies network against. 
testsite=http://google.com

# Set the page that you want the kiosk to open to.
homePage=https://google.com

# Set to yes if you want to install Citrix Receiver.
citrix=no

# Set to yes if you want to install Citrix USB Support
citrixusb=no

# Set to yes if you want to install Citrix Web Receiver
citrixweb=no

# Echo function
echoFunc () {
	# Date and Time function for the log file
	fDateTime () { echo $(date +"%a %b %d %T"); }

	# Title for beginning of line in log file
	Title="Create Fedora Kiosk"

	# Header string function
	fHeader () { echo $(fDateTime) $(hostname) $Title; }

	# Check for the log file
	if [ -e ${log} ]; then
		echo $(fHeader) "$1" >> $log
	else
		cat "" > $log
		if [ -e $log ]; then
			echo $(fDateTime) "$1" >> $log
		else
			echo "Failed to create log file. Please check your configuration." 
			exit 5
		fi
	fi

	# Echo out
	echo $1
}

# Function to install packages by name. It checks to see if they're already installed or not. 
installPackage () {
	if ! rpm -qa | grep -qw $1 ; then
		echoFunc "Installing: $1"
		echo -n "Progress: "
		dnf -y install $1 >> $log &
		while [ -e /proc/$! ] ; do
			echo -n "."
			sleep 5
		done
		echoFunc "Finished."
	else
		echoFunc "$1: already installed."
	fi
}


# Starting script!
echoFunc "Starting script"
echoFunc ""
echoFunc "This script will install additional packages and make changes to system files to have the computer start in kiosk mode after the next reboot."
echoFunc "A log file can be found ${log} for additional information and troubleshooting."
echoFunc ""

# Checking if we're root.
if [ $user != root ];then
	echoFunc "You must be root. Please sudo or su and try again."
	echoFunc "The script was started as: ${user}"
	echoFunc "Exiting with error code: 1"
	exit 1
fi

# Testing to see if the OS is right.
if [ $cpu = x86_64 ] || [ $cpu = i386 ]; then
	echoFunc "Kernel architecture is: ${cpu}"
else
	echoFunc "Unsupported architecture found: ${cpu}"
	echoFunc "Supported architectures are: i386 x86_64"
	echoFunc "Exiting with error code: 6"
	exit 6
fi

if [ ! -f /etc/fedora-release ] ; then
    echoFunc "Sorry, your Linux distribution isn't supported by this script."
    echoFunc "Unsupported Linux distro: ${releaseinfo}"
    echoFunc "Error! Exiting with code: 6"
    exit 6
fi
echoFunc "Release Version: ${releaseinfo}"
if [ $elver -ge 25 ] ; then
	echoFunc "Version is: ${elver}"
else
	echoFunc "You need to be running fedora version 25 or later."
	echoFunc "Unsupported Fedora version: ${elver}"
	echoFunc "Error! Exiting with code:6"
	exit 6
fi

# Verify there's a network connection
case "$(curl -s --max-time 2 -I $testsite | sed 's/^[^ ]*  *\([0-9]\).*/\1/; 1q')" in
	[23]) 
		echoFunc "Network is up! Yay!"
		;;
	5) 
		echoFunc "Error: A web proxy won't let us through."
		echoFunc "Exiting with error code 2."
		exit 2
		;;
	*)
		echoFunc "Error: The network is down or very slow."
		echoFunc "Exiting with error code 2."
		exit 2
		;;
esac

# Adding kiosk user
if [ -z "$(getent passwd kiosk)" ] ; then
    echoFunc "Adding the user 'kiosk' to the system."
    useradd kiosk
else
    echoFunc "The user 'kiosk' already exists."
fi

# Start installing some dependancies. 
echoFunc "Installing dependancies:"
echoFunc "This section will be downloading over 600 MB and will take a significant amount of time."
echoFunc "Overall Progress: 5%"
echoFunc "Installing: Basic Desktop Group"
dnf -y group install "Basic Desktop" >> $log &
echo -n "Progress: "
while [ -e /proc/$! ] ; do 
	echo -n "."
	sleep 5
done
echoFunc "Finished."
echoFunc "Overall Progress 25%"
installPackage "gdm"
installPackage "matchbox-window-manager"
echoFunc "Overall Progress: 40%"
installPackage "gnome-session-xsession"
installPackage "xorg-x11-xinit-session"
echoFunc "Overall Progress: 50%"
installPackage "chromium"

if [ $citrix = yes ] ;then
	echoFunc "Downloading Citrix Receiver (Full)"
	url1="https:"
	url2=`curl -s -L "https://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-latest.html#ctx-dl-eula-external" | grep ICAClient-rhel.*${cpu}.rpm? | sed 's/.*rel=.\(.*\)..id=.*/\1/'`
	url=`echo "${url1}${url2}"`
	curl -s -o /tmp/ICAClient-rhel.${cpu}.rpm "${url}"
	echoFunc "Download complete."
	installPackage "/tmp/ICAClient-rhel.${cpu}.rpm"
	echoFunc "Removing temp file."
	rm /tmp/ICAClient-rhel.${cpu}.rpm

else
	echoFunc "Skipping Citrix (FULL) Receiver install."
fi

if [ $citrixweb = yes ] ;then
        echoFunc "Downloading Citrix Receiver for Web"
        url1="https:"
        url2=`curl -s -L "https://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-latest.html#ctx-dl-eula-external" | grep ICAClientWeb-rhel.*${cpu}.rpm? | sed 's/.*rel=.\(.*\)..id=.*/\1/'`
        url=`echo "${url1}${url2}"`
        curl -s -o /tmp/ICAClientWeb-rhel.${cpu}.rpm "${url}"
        echoFunc "Download complete."
        installPackage "/tmp/ICAClientWeb-rhel.${cpu}.rpm"
        echoFunc "Removing temp file."
        rm /tmp/ICAClientWeb-rhel.${cpu}.rpm
else
        echoFunc "Skipping Citrix Receiver for Web install."
fi

if [ $citrixusb = yes ] ;then
	echoFunc "Installing Citrix USB Support"
	url1="https:"
	url2=`curl -s -L "https://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-latest.html#ctx-dl-eula-external" | grep ctxusb.*${cpu}.rpm? | sed 's/.*rel=.\(.*\)..id=.*/\1/'`
	url=`echo "${url1}${url2}"`
	curl -s -o /tmp/ctxusb.${cpu}.rpm "${url}"
	echoFunc "Download complete."
	installPackage "/tmp/ctxusb.${cpu}.rpm"
	echoFunc "Removing temp file."
	rm /tmp/ctxusb.${cpu}.rpm
else
	echoFunc "Skipping Citrix USB Support."
fi

echoFunc "Overall Progress: 80%"


# Run some tests to make sure that the programs actually installed. 

if [ ! $( rpm -qa | grep -w chromium ) ] ; then
        echoFunc "Chromium not found!"
	echoFunc "Exiting with error code: 3"
	exit 3
else
        echo "Chromium install verified"
fi


if [ $citrix = yes ] && [ -e /opt/Citrix/ICAClient/wfica ] ; then
	echoFunc "Citrix install verified."
else
	if [ $citrix = yes ] ; then
		echoFunc "Citrix seemed to fail the install."
		echoFunc "Exiting with error code: 4"
		exit 4
	fi
fi


if [ $citrixweb = yes ] && [ -e /opt/Citrix/ICAClient/wfica ] ; then
        echoFunc "Citrix install verified."
else
        if [ $citrixweb = yes ] ; then
                echoFunc "Citrix seemed to fail the install."
                echoFunc "Exiting with error code: 4"
                exit 4
        fi
fi


# Config Machine for Kiosk Attributes
echoFunc "Checking login manager (GDM) for automatic login."
autologin=$( cat /etc/gdm/custom.conf | grep AutomaticLoginEnable=True )
loginname=$( cat /etc/gdm/custom.conf | grep AutomaticLogin=kiosk )
if [ -n "$autologin" ]
then
	echoFunc "File is already configured for automatic login."
	echoFunc "Current automatic login config: ${autologin}"
	echoFunc "Check the GDM file /etc/gdm/custom.conf."
	cat /etc/gdm/custom.conf 1>> $log 2>> $log
else
	echoFunc "Adding line to /etc/gdm/custom.conf for automatic login."
	sed -i '/daemon]/aAutomaticLoginEnable=True' /etc/gdm/custom.conf
fi
if [ -n "$loginname" ]
then
	echo "File is already configured for a user to autologin."
	if [$(echo $loginname | sed 's/AutomaticLogin=//g') != kiosk ]
	then
		echoFunc "A different user was set to automatically login: ${loginname}"
		echoFunc "Changing the user to kiosk"
		sed "s/${loginname}/AutomaticLogin=kiosk/" /etc/gdm/custom.conf
		echoFunc "User replaced."
	else
		echoFunc "User: 'kiosk' was already configured."
	fi
else
	echoFunc "Adding lines to enable kiosk user in /etc/gdm/custom.conf"
	sed -i '/AutomaticLoginEnable=True/aAutomaticLogin=kiosk' /etc/gdm/custom.conf
fi
echoFunc "Adding line to /etc/gdm/custom.conf for default X Session."
echoFunc "And creating session file for specific user in /var/lib/AccountsService/users/kiosk."
sed -i '/AutomaticLogin=kiosk/aDefaultSession=xinit-compat.desktop' /etc/gdm/custom.conf
touch /var/lib/AccountsService/users/kiosk
chmod 644 /var/lib/AccountsService/users/kiosk
echo "[User]" >> /var/lib/AccountsService/users/kiosk
echo "Language=" >> /var/lib/AccountsService/users/kiosk
echo "XSession=xinit-compat" >> /var/lib/AccountsService/users/kiosk
echo "SystemAccount=false" >> /var/lib/AccountsService/users/kiosk

echoFunc "Overall Progress: 90%"

echoFunc "Configuring system to start in graphical mode."
systemctl set-default graphical.target
echoFunc "Enableing GDM"
systemctl enable gdm

# Rewrite the firstboot file.
echoFunc "Disabling firstboot."
chkconfig firstboot off
echo "RUN_FIRSTBOOT=no" > /etc/sysconfig/firstboot
rpm -e initial-setup initial-setup-gui

# Create conf files in /home/kiosk.
echoFunc "Generating new .xsession file."
cat << EOF > /home/kiosk/.xsession
xset s off
xset -dpms
matchbox-window-manager &
while true; do
	chromium-browser --kiosk --incognito --no-default-browser-check --no-first-run --homepage '$homePage'
done
EOF
chmod +x /home/kiosk/.xsession

# Create .dmrc file
echoFunc "Creating .dmrc desktop profile session file."
echo "[Desktop]" > /home/kiosk/.dmrc
echo "Session=xinit-compat" >> /home/kiosk/.dmrc
echo "Language=$LANG" >> /home/kiosk/.dmrc

# Avoid Gnome's Initial Setup. 
echoFunc "Creating config to diable Gnome's initial setup."
mkdir -p /home/kiosk/.config
echo "yes" > /home/kiosk/.config/gnome-initial-setup-done

# Modify magic file for citrix mime-type and accept eula
if [ $citrix = yes ] || [ $citrixweb = yes ] ; then
	echo "# Citrix File Types" >> /usr/share/misc/magic
	echo "20	search/50	WFClient	Citrix Client File" >> /usr/share/misc/magic
	echo "!:mime	application/x-ica" >> /usr/share/misc/magic
	cd /usr/share/misc
	file -C -m /usr/share/misc/magic 
	cd ~/
	# Accept EULA to avoid dialog at first start
	mkdir /home/kiosk/.ICAClient
	touch /home/kiosk/.ICAClient/.eula_accepted
fi

# Cleanup
echoFunc "Cleaning up some cached items for additional space."
dnf -y clean all

# Force ~/ ownship for kiosk
echoFunc "Checking home disk partions"
chown -Rfv kiosk:kiosk /home/kiosk

# All done!
echoFunc "Overall Progress: 100%"
echoFunc "Script Complete."
echoFunc "Please reboot your computer for changes to take effect."
echoFunc "Exiting successfully with code: 0"
exit 0
