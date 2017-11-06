<#
.NOTES 
	Name: Install-Firefox-Silent.ps1
	Author: Brian Monroe
	License: MIT
	Requires: PowerShell v4 or later, Windows 7, 8, or 10.
	Version History:
	1.0 - 11/1/2017 - Initial Release

.SYNOPSIS 
	Downloads and installs the latest version of Firefox from Mozilla's website.

.SYNTAX
	[PS] C:\>.\Install-Firefox-Silent.ps1

.DESCRIPTION 
	This script will download the latest version of Firefox from Mozilla's 
    website. The script then silently installs Firefox and removes downloaded 
    files.

.RELATED LINKS
	https://www.github.com/azusapacificuniversity/

.EXAMPLE 

	[PS] C:\>.\Install-Firefox-Silent.ps1
#>

# Set some variables:
$Path = "C:\Windows\Installers\"
$source = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"
$Installer = "firefox.exe"
$InstallerPath = "$Path$($Installer)"

# Check if Path exists, and if not create it. 
if (Test-Path -Path $Path -PathType Container)
{ Write-Host "$Path already exists"}
else
{ 
    New-Item -Path $Path  -ItemType directory 
    Write-Host "Created $Path"
}

# Download the installer
Write-Host "Downloading $Installer."
Invoke-WebRequest $source -OutFile $InstallerPath

# Start the installation
Write-Host "Starting Install."
Start-Process -FilePath $InstallerPath -ArgumentList "/S" -NoNewWindow -Wait

# Remove the installer
Write-Host "Removing $Installer"
rm -Force $InstallerPath

exit
