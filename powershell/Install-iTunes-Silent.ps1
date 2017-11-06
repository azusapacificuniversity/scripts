<#
.NOTES 
	Name: Install-iTunes-Silent.ps1
	Author: Brian Monroe
	License: MIT
	Requires: PowerShell v4 or later, Windows 7, 8, or 10.
	Version History:
	1.0 - 11/1/2017 - Initial Release

.SYNOPSIS 
	Downloads and installs the latest version of iTunes from Apple's website.

.SYNTAX
	[PS] C:\>.\Install-iTunes-Silent.ps1

.DESCRIPTION 
	This script will download the latest version of iTunes from Apple's
    website. Then iTunes is installed silently and script removes downloaded 
    files.

.RELATED LINKS
	https://www.github.com/azusapacificuniversity/scripts

.EXAMPLE 
	[PS] C:\>.\Install-iTunes-Silent.ps1
#>

# Set some variables:
$Path = "C:\Windows\Installers\"
$Installer = "iTunes64Setup.exe"
$iFrame = (
	# Format HTML code from Apple's download page as strings
	Invoke-WebRequest "https://www.apple.com/itunes/download" | fl * | Out-String -Stream |
	# Grab the line with the link to the iframe HTML
	sls -Pattern "iframe" | select-object -First 1 |
	# Use regex to strip out the unwanted bits. 
	%{$_ -replace ".*src=.",""} | %{$_ -replace ". title=.*",""}
)
$DownloadURL = (
	# Format the HTML code from iFrame as a strings
	Invoke-WebRequest $iFrame | fl * | Out-String -stream |
	# Find the first line with the downloader link
	sls -Pattern "https://.*iTunes64Setup.exe" | select-object -First 1 |
	# Use regex to strip out the unwanted bits
	%{$_ -replace ".*alue='",""} | %{$_ -replace "' >.*",""}
)

# Check if Path exists, and if not create it. 
if (Test-Path -Path $Path -PathType Container)
{ Write-Host "$Path already exists"}
else
{ 
    New-Item -Path $Path  -ItemType directory 
    Write-Host "Created $Path"
}

# Download the latest installer from Apple
Write-Host "Downloading $Installer"
Invoke-WebRequest $DownloadURL -OutFile $Path$($Installer)

# Install iTunes
Write-Host "Starting Install."
Start-Process -Wait -NoNewWindow $Path$($Installer) -ArgumentList '/qn /norestart'

# Cleanup
Remove-Item $Path$($Installer)
Write-Host "Removed $Installer"

exit
