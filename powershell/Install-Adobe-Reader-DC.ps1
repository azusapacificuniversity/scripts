<#
.NOTES 
	Name: Install-Adobe-Reader-DC.ps1
	Author: Brian Monroe
	License: MIT
	Requires: PowerShell v4 or later, Windows 7, 8, or 10.
	Version History:
	1.0 - 11/1/2017 - Initial Release

.SYNOPSIS 
	Downloads and installs the latest version of Adobe Reader DC from Adobe's website.

.SYNTAX
	[PS] C:\>.\Install-Adobe-Reader

.DESCRIPTION 
	This script will parse Adobe's website in an effort to obtain the latest version 
	number. After that it builds a downloads link and downloads the latest installer 
	to a local folder. The installation is done with touchless deployment, but it 
	doesn't suppress all output. The script removes downloaded files.

.RELATED LINKS
	https://www.github.com/azusapacificuniversity/scripts

.EXAMPLE 
	[PS] C:\>.\Install-Adobe-Reader
#>

# Set some variables
$Path = "C:\Windows\Installers\"
# This gets the latest version through the the Apple Version when safari visists the page. 
$LatestVersion = (
	# Download HTML code for Safari's version of the download page
	(Invoke-WebRequest -Uri "https://get.adobe.com/reader/" -UserAgent "Mozilla/5.0 (Macintosh; Intel Mac OS X ${OSvers_URL}) AppleWebKit/535.6.2 (KHTML, like Gecko) Version/5.2 Safari/535.6.2") |
	# Format the output and return the first matching line that contains the version number
	fl * | out-string -stream | sls -Pattern "<strong>Version 20" | select-object -First 1 |
	# Use some Regex to strip out unwanted bits
	%{$_ -replace ".*Version 20",""} |  %{$_ -replace "<.STRONG.*",""} |  %{$_ -replace "\.",""} 
)
$DownloadURL = "http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/$($LatestVersion)/AcroRdrDC$($LatestVersion)_en_US.exe"
$Installer = "AcroRdrDC$($LatestVersion)_en_US.exe"

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
Invoke-WebRequest "$DownloadURL" -OutFile $Path$($Installer)

# Install Adobe Acrobat Reader
Write-Host "Starting Install."
Start-Process -FilePath $Path$($Installer) -ArgumentList "/sPB /rs" -Wait

# Cleanup
Write-Host "Removing $Installer"
Remove-Item $Path$($Installer)

exit
