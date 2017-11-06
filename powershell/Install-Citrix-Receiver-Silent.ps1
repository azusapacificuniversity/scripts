<#
.NOTES 
	Name: Install-Citrix-Receiver-Silent.ps1
	Author: Brian Monroe
	License: MIT
	Requires: PowerShell v4 or later, Windows 7, 8, or 10.
	Version History:
	1.0 - 11/1/2017 - Initial Release

.SYNOPSIS 
	Downloads and installs the latest version of VLC Player from the website.

.SYNTAX
	[PS] C:\>.\Install-Citrix-Receiver-Silent.ps1

.DESCRIPTION 
	This script will download the latest version of Citrix Receiver from 
	Citrix's website. Then Citrix is installed silently and script removes 
	downloaded files. You can set the Store variable to have Receiver set 
	up with a specific storefront. 

.RELATED LINKS
	https://www.github.com/azusapacificuniversity/scripts

.EXAMPLE 
	[PS] C:\>.\Install-Citrix-Receiver-Silent.ps1
#>

# Variables
$Store = ""
$Path = "C:\Windows\Installers\"
$DownloadPage = "https://www.citrix.com/downloads/citrix-receiver/windows/receiver-for-windows-latest.html#ctx-dl-eula"
$Installer = "CitrixReceiver.exe"
$DownloadPath = ( 
    #Download the HTML code for the dl page and format it so it can be searched
    Invoke-WebRequest $DownloadPage | fl * | Out-String -Stream |
    #Grab the first line that contains the download path
    sls -Pattern "rel.*exe\?" | select-object -First 1 |
    # Use some regex to strip out unwanted bits.
    %{$_ -replace ".*rel=.",""} | %{$_ -replace "[^a-zA-z\d]*$",""} 
)
# Add the protocol to create a Url.
$DownloadUrl = "https:$DownloadPath"


# Check if Path exists, and if not create it. 
if (Test-Path -Path $Path -PathType Container)
{ Write-Host "$Path already exists"}
else
{ 
    New-Item -Path $Path  -ItemType directory 
    Write-Host "Created $Path"
}

# Download the latest installer from Citrix
Write-Host "Downloading $Installer."
Invoke-WebRequest $DownloadUrl -OutFile "$Path$($Installer)"

# Install Citrix Receiver
Write-Host "Starting Install."
Start-Process -Wait -NoNewWindow -FilePath "$Path$($Installer)" -Args "/silent /noreboot $Store"

# Cleanup
Write-Host "Removing $Installer"
Remove-Item $Path\$Installer

exit
