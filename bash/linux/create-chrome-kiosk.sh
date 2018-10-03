#!/bin/bash
###############################################################################
#
# Create Chrome Kiosk
#
###############################################################################
#
# NAME: 
#	create-chrome-kiosk.sh
#
# LICENSE:
#	Distributed uner the MIT License.
#
# SYNOPSIS:
#	sudo ./create-chrome-kiosk.sh
#
# REQUIREMENTS:
#	OS: CentOS/RHEL version 6 or newer.
#	Arch: x86_64
#	Requires active network conenction.
#
# DESCRIPTION:
#	This script converts a RHEL or CentOS install into Google Chrome kiosk. 
#	You may choose to set variables that also install the version of Citrix
#	Receiver. Setting the start page to your webstore will effectively 
#	create a thin client image for Citrix Receiver. A local user, called
#	kiosk, will be created and set to auto login. You can also choose to
#	limit traffic to certain sites. 
#
# EXIT CODES:
#	0 - Success
#	1 - Failed - Needs to be run as root.
#	2 - Network Failure - Are you online?
#	3 - Failed to download/install Google Chrome.
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
releaseinfo=$( cat /etc/*-release )
elver=$( cat /etc/redhat-release | sed 's/.*release \([0-9]\).*/\1/' )

# You can set cpu manually to specify an arch (like cpu=i386) if you wish.
cpu=$( uname -i )

# This is website that the script verifies network against. 
testsite=http://google.com

# Set the page that you want the kiosk to open to.
homePage=https://google.com

# Set to yes if you also want to install Adobe Flash.
flash=no

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
	Title="Create Chrome Kiosk"

	# Header string function
	fHeader () { echo $(fDateTime) $(hostname) $Title; }

	# Check for the log file
	if [ -e ${log} ]; then
		echo $(fHeader) "$1" >> $log
	else
		cat "" > $log
		if [ -e $log ]; then
			echo $(fHeader) "$1" >> $log
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
		yum -y install $1 >> $log
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
if [ $cpu = x86_64 ]; then
	echoFunc "Kernel architecture is: ${cpu}"
else
	echoFunc "Unsupported architecture found: ${cpu}"
	echoFunc "Supported architectures are: x86_64"
	echoFunc "Exiting with error code: 6"
	exit 6
fi
if [ ! -f /etc/redhat-release ] ; then
    echoFunc "Sorry, your Linux distribution isn't supported by this script."
    echoFunc "Unsupported Linux distro: ${releaseinfo}"
    echoFunc "Error! Exiting with code: 6"
    exit 6
fi
echoFunc "Release Version: ${releaseinfo}"
if [ $elver -ge 6 ] ; then
	echoFunc "Version is: ${elver}"
else
	echoFunc "You need to be running RHEL/CentOS version 6 or newer."
	echoFunc "Unsupported RHEL version: ${elver}"
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
echoFunc "Overall Progress: 5%"

# Adding kiosk user
if [ -z "$(getent passwd kiosk)" ] ; then
    echoFunc "Adding the user 'kiosk' to the system."
    useradd kiosk
else
    echoFunc "The user 'kiosk' already exists."
fi

# Start installing some dependancies. 
echoFunc "Installing dependancies:"
echoFunc "This section will be downloading over 400 MB and will take a significant amount of time."

# wget
installPackage "wget"
echoFunc "Overall Progress: 10%"
echoFunc "Installing: X11"
yum -y groupinstall basic-desktop x11 fonts base-x
echoFunc "Finished."
echoFunc "Overall Progress 40%"
installPackage "gdm"
installPackage "matchbox-window-manager"
echoFunc "Overall Progress: 55%"
installPackage "rsync"
installPackage "gnome-session-xsession"
installPackage "xorg-x11-xinit-session"
echoFunc "Installing Google Chrome Repo"
cat << EOF > /etc/yum.repos.d/google-chrome.repo
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
echoFunc "Overall Progress: 65%"
installPackage "google-chrome-stable"

if [ $flash = yes ] ;then
	echoFunc "Installing Flash."
	rpm -ivh http://linuxdownload.adobe.com/adobe-release/adobe-release-x86_64-1.0-1.noarch.rpm
	rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-adobe-linux
	yum -y check-update
    	yum -y install flash-plugin nspluginwrapper alsa-plugins-pulseaudio libcurl
	echoFunc "Finished"
else
	echoFunc "Skipping Adobe Flash install."

fi
echoFunc "Overall Progress: 70%"

if [ $citrix = yes ] ;then
	echoFunc "Downloading Citrix Receiver (Full)"
	url1="https:"
	url2=`curl -s -L "https://www.citrix.com/downloads/citrix-receiver/linux/receiver-for-linux-latest.html#ctx-dl-eula-external" | grep ICAClient-rhel.*${cpu}.rpm? | sed 's/.*rel=.\(.*\)..id=.*/\1/'`
	url=`echo "${url1}${url2}"`
	curl -s -o /tmp/ICAClient-rhel.${cpu}.rpm "${url}"
	echoFunc "Download complete. Installing."
	yum -y localinstall /tmp/ICAClient-rhel.${cpu}.rpm
	echoFunc "Finished. Removing temp file."
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
        echoFunc "Download complete. Installing."
        yum -y localinstall /tmp/ICAClientWeb-rhel.${cpu}.rpm
        echoFunc "Finished. Removing temp file."
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
	echoFunc "Download complete. Installing."
	yum -y localinstall /tmp/ctxusb.${cpu}.rpm
	echoFunc "Finished. Removing temp file."
	rm /tmp/ctxusb.${cpu}.rpm
else
	echoFunc "Skipping Citrix USB Support."
fi

echoFunc "Overall Progress: 80%"


# Run some tests to make sure that the programs actually installed. 
if [ -e /opt/google/chrome/chrome ] ; then
	echoFunc "Chrome install verified."
else
	echoFunc "Chrome doesn't seem to be installed."
	echoFunc "Exiting with error code: 3"
	exit 3
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
if [ $elver -ge 7 ] ;then
	echoFunc "Adding line to /etc/gdm/custom.conf for default X Session in EL7."
	echoFunc "And creating session file for specific user in /var/lib/AccountsService/users/kiosk."
	sed -i '/AutomaticLogin=kiosk/aDefaultSession=xinit-compat.desktop' /etc/gdm/custom.conf
	touch /var/lib/AccountsService/users/kiosk
	chmod 644 /var/lib/AccountsService/users/kiosk
	echo "[User]" >> /var/lib/AccountsService/users/kiosk
	echo "Language=" >> /var/lib/AccountsService/users/kiosk
	echo "XSession=xinit-compat" >> /var/lib/AccountsService/users/kiosk
	echo "SystemAccount=false" >> /var/lib/AccountsService/users/kiosk
else
	echoFunc "No need for default session in gdm.conf."
fi

echoFunc "Overall Progress: 90%"

echoFunc "Configuring system to start in graphical mode."
if [ $elver -ge 7 ] ;then
	echoFunc "Setting system to graphical target"
	systemctl set-default graphical.target
else
	gfxboot=$( cat /etc/inittab | grep id:5:initdefault: )
	if [ -n "$gfxboot" ]
	then
		echo "System is already configured for graphical boot."
	else
		echo "Parsing /etc/inittab for graphical boot."
		sed -i 's/id:1:initdefault:/id:5:initdefault:/g' /etc/inittab
		sed -i 's/id:2:initdefault:/id:5:initdefault:/g' /etc/inittab
		sed -i 's/id:3:initdefault:/id:5:initdefault:/g' /etc/inittab
		sed -i 's/id:4:initdefault:/id:5:initdefault:/g' /etc/inittab
	fi
fi

# Rewrite the firstboot file.
echoFunc "Disabling firstboot."
chkconfig firstboot off
echo "RUN_FIRSTBOOT=no" > /etc/sysconfig/firstboot
rpm -e initial-setup initial-setup-gui

# Create conf files in /home/kiosk.
echoFunc "Generating new .xsession file."
echo "xset s off" > /home/kiosk/.xsession
echo "xset -dpms" >> /home/kiosk/.xsession
echo "matchbox-window-manager &" >> /home/kiosk/.xsession
echo "while true; do" >> /home/kiosk/.xsession
echo "/opt/google/chrome/chrome --kiosk --incognito --no-first-run --homepage '$homePage'" >> /home/kiosk/.xsession
echo "done" >> /home/kiosk/.xsession
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

# Modify magic file for citrix mime-type
if [ $citrix = yes ] || [ $citrixweb = yes ] ; then
	echo "# Citrix File Types" >> /usr/share/misc/magic
	echo "35	string		[WFClient]	Citrix Client File" >> /usr/share/misc/magic
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
yum -y clean all

# Force ~/ ownship for kiosk
echoFunc "Checking home disk partions"
chown -Rfv kiosk:kiosk /home/kiosk

# All done!
echoFunc "Overall Progress: 100%"
echoFunc "Script Complete."
echoFunc "Please reboot your computer for changes to take effect."
echoFunc "Exiting successfully with code: 0"
exit 0
