<#
.NOTES 
	Name: Install-Google-FileStream-Silent.ps1
	Author: Brian Monroe
	License: MIT
	Requires: PowerShell v4 or later, Windows 7, 8, or 10.
	Version History:
	1.0 - 11/1/2017 - Initial Release

.SYNOPSIS 
	Downloads and installs the latest version of File Stream For Drive from Google's website.

.SYNTAX
	[PS] C:\>.\Install-Google-FileStream-Silent.ps1

.DESCRIPTION 
	This script will download the latest version of File Stream For 
	Drive from Google's website. Then FileStream is installed silently 
	and script removes downloaded files.

.RELATED LINKS
	https://www.github.com/azusapacificuniversity/scripts

.EXAMPLE 
	[PS] C:\>.\Install-Google-FileStream-Silent.ps1
#>

# Set Some Variables:
$Source = "https://dl.google.com/drive-file-stream/GoogleDriveFSSetup.exe"
$Path = "C:\Windows\Installers\"
$Installer = "GoogleDriveFSSetup.exe"

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

# Install FileStream
Write-Host "Starting Install."
Start-Process -FilePath $Path$($Installer) -Args "--silent" -Verb RunAs -Wait

# Cleanup
Remove-Item $Path$($Installer)
Write-Host "Removed $Installer"
exit
