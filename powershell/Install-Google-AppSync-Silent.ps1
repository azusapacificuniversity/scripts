<#
.NOTES 
	Name: Install-Google-AppSync-Silent.ps1
	Author: Brian Monroe
	License: MIT
	Requires: PowerShell v4 or later, Windows 7, 8, or 10.
	Version History:
	1.0 - 11/1/2017 - Initial Release

.SYNOPSIS 
	Downloads and installs the latest version of Google Sync for Outlook 
    from Google's website.

.SYNTAX
	[PS] C:\>.\Install-Google-AppSync-Silent.ps1

.DESCRIPTION 
	This script will download the latest version of Google App Sync for 
    Outlook from Google's website. The script then silently installs, then 
    removes downloaded files.

.RELATED LINKS
	https://www.github.com/azusapacificuniversity/

.EXAMPLE 

	[PS] C:\>.\Install-Google-AppSync-Silent.ps1
#>

# Set Some Variables:
$Source = "http://dl.google.com/dl/google-apps-sync/x64/enterprise_gsync.msi"
$Path = "C:\Windows\Installers\"
$Installer = "enterprise_gsync.msi"

# Check if Path exists, and if not create it. 
if (Test-Path -Path $Path -PathType Container)
{ Write-Host "$Path already exists"}
else
{ 
    New-Item -Path $Path  -ItemType directory 
    Write-Host "Created $Path"
}

# Download the Installer
Write-Host "Downloading $Installer."
Invoke-WebRequest "$Source" -OutFile $Path$($Installer)

# Install FileStream
Write-Host "Starting Install."
Start-Process msiexec.exe -Wait -ArgumentList "/I $Path$($Installer) /qn"

# Cleanup
Write-Host "Removing $Installer"
Remove-Item $Path$($Installer)

exit
