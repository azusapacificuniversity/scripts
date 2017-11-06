<#
.NOTES 
	Name: Install-Google-Chrome-Silent.ps1
	Author: Brian Monroe
	License: MIT
	Requires: PowerShell v4 or later, Windows 7, 8, or 10.
	Version History:
	1.0 - 11/1/2017 - Initial Release

.SYNOPSIS 
	Downloads and installs the latest version of Chrome from Google's website.

.SYNTAX
	[PS] C:\>.\Install-Google-Chrome-Silent.ps1

.DESCRIPTION 
	This script will download the latest version of chrome from Google's 
	website. Then Chrome is installed silently and script removes downloaded 
 	files.

.RELATED LINKS
	https://www.github.com/azusapacificuniversity/scripts

.EXAMPLE 
	[PS] C:\>.\Install-Google-Chrome-Silent.ps1
#>

# Set some variables:
$Path = "C:\Windows\Installers\"
$Source = "http://dl.google.com/chrome/install/stable/chrome_installer.exe"
$Installer = "chrome_installer.exe"

# Check if Path exists, and if not create it. 
if (Test-Path -Path $Path -PathType Container)
{ Write-Host "$Path already exists"}
else
{ 
    New-Item -Path $Path  -ItemType directory 
    Write-Host "Created $Path"
}

# Download the Installer
Write-Host "Downloading $Installer"
Invoke-WebRequest "$Source" -OutFile $Path$($Installer)

# Install Chrome
Write-Host "Starting Install."
Start-Process -FilePath $Path$($Installer) -Args "/silent /install" -Verb RunAs -Wait

# Cleanup
Remove-Item $Path$($Installer)
Write-Host "Deleted $Installer"

exit
