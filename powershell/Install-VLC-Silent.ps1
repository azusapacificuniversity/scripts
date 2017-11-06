<#
.NOTES 
	Name: Install-VLC-Silent.ps1
	Author: Brian Monroe
	License: MIT
	Requires: PowerShell v4 or later, Windows 7, 8, or 10.
	Version History:
	1.0 - 11/1/2017 - Initial Release

.SYNOPSIS 
	Downloads and installs the latest version of VLC Player from the website.

.SYNTAX
	[PS] C:\>.\Install-VLC-Silent.ps1

.DESCRIPTION 
	This script will download the latest version of the Video Lan Codec
	Player from VLC's website. Then VLC is installed silently 
	and script removes downloaded files.

.RELATED LINKS
	https://www.github.com/azusapacificuniversity/scripts

.EXAMPLE 
	[PS] C:\>.\Install-VLC-Silent.ps1
#>

# Variables
$Source = "https://get.videolan.org/vlc/last/win64/" 
$Path = "C:\Windows\Installers\"
$Installer = (( Invoke-WebRequest $Source ).Links | Where href -like "*win64.exe").href 
$DownloadLink = (
	# Grab HTML from download page and format it in strings	
	Invoke-WebRequest "$Source$($Installer)" | fl * | Out-String -Stream |
	# Grab the first line with the download link (mirror site)
	sls -Pattern "click here" | select-object -First 1 |
	# Use regex to cut out the unwanted bits
	%{$_ -replace ".*href=.",""} | %{$_ -replace ".\sid=.*",""} 
)


# Check if Path exists, and if not create it. 
if (Test-Path -Path $Path -PathType Container)
{ Write-Host "$Path already exists"}
else
{ 
    New-Item -Path $Path  -ItemType directory 
    Write-Host "Created $Path"
}

# Download the latest installer from VLC
Write-Host "Downloading $Installer."
Invoke-Webrequest $DownloadLink -OutFile "$Path$($Installer)"

# Install VLC
Write-Host "Starting Install."
Start-Process -FilePath "$Path$($Installer)" -Args "/L=1033 /S" -Wait

# Cleanup
Write-Host "Removing $Installer"
Remove-Item $Path\$Installer

exit
