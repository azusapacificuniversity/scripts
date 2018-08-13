##################################################################
<#
.NOTES 
	Name: Veeam-vCenter-Backups.ps1
	Author: Brian Monroe
	License: MIT
	Requires: PowerShell v4 or later, PowerCLI, VeeamPSSnapin,
              vCenter, and Veeam (Free version or higher)
	Version History:
	1.0 - 08/13/2018 - Initial Release
.SYNOPSIS 
	Queries vcenter and gets a list of VMs to backup through Veeam
.SYNTAX
	[PS] C:\>.\Veeam-vCenter-Backups.ps1
.DESCRIPTION 
	This Script will utilize Veeam to automatically backup VMs from
    a vCenter instance. It's designed to be run programatically. You
    will need to have PowerCLI and Veeam (and the VeeamPSSnapin) 
    installed locally. 
.RELATED LINKS
	https://www.github.com/azusapacificuniversity/scripts
.EXAMPLE 
	[PS] C:\>.\Veeam-vCenter-Backups.ps1
#>
##################################################################
# User Defined Variables
##################################################################

# FQDN or IP of vcenter instance
$HostName = "your-vcenter.example.com"

# Specify What VMs you want to back up by listing the name of the ResourcePool, VApp, VMHost, Folder, Cluster, or Datacenter. An * will imply all VMs in the server instance.
$LocationName = "*"

# Directory that VM backups should go to
$Directory = "\\fileserver.example.com\ShareName"

# Desired compression level, following compression level from Veeam (Optional)
$CompressionLevel = “4”

# Quiesce VM when taking snapshot (Optional; VMware Tools are required; Possible values: $True/$False)
$EnableQuiescence = $False

# Protect resulting backup with encryption key (Optional; $True/$False)
$EnableEncryption = $False

# Encryption Key (Optional; path to a secure string, C:\SecureString.txt”
$EncryptionKey = “”

# Retention settings (Optional; By default, VeeamZIP files are not removed and kept in the specified location for an indefinite period of time.
# Possible values: Never , Tonight, TomorrowNight, In3Days, In1Week, In2Weeks, In1Month)
$Retention = “Never”

# Email Settings
# Enable notification (Optional)
$EnableNotification = $True

# Email SMTP server
$SMTPServer = “smtp.example.com”

# Email FROM
$EmailFrom = “veeam-noreply@example.com”

# Email TO
$EmailTo = “you@example.com"

# Email subject
$EmailSubject = “Veeam vSphere Backup - $LocationName”
If ( $LocationName -eq "*" ) { $EmailSubject = $EmailSubject + " $HostName *"}

# Email Table formatting
$style = “<style>BODY{font-family: Arial; font-size: 10pt;}”
$style = $style + “TABLE{border: 1px solid black; border-collapse: collapse;}”
$style = $style + “TH{border: 1px solid black; background: #54b948; padding: 5px; }”
$style = $style + “TD{border: 1px solid black; padding: 5px; }”
$style = $style + “</style>”

##################################################################
# End User Defined Variables
##################################################################

# Add the Veeam snapin.
Asnp VeeamPSSnapin 

# Check that powershell is installed. 
Try {
    Get-PowerCLIVersion | Out-Null}
catch [Exception]{
    Write-Host "PowerCLI is not installed. Please try again after installing." -ForegroundColor Red
    exit 1}

# Verify vcenter server.
$Server = Get-VBRServer -name $HostName

# Initiate array for Email body and VM List. 
$mbody = @()
$VMNames = @()

# Set up the Failure Count for jobs that fail or have warnings
$FailureCount = 0

# Start Timestamp
$start = Get-Date

# Connect to the vCenter through PowerCLI and if you can't, quit. 
Try {
    Connect-VIServer -server $HostName -NotDefault -Force -ErrorAction Stop | Out-Null
}
catch [Exception]{
    Write-Host "Unable to connect to vcenter server: $HostName" -ForegroundColor Red
    Write-Host "Exiting" -ForegroundColor Red
    If ($EnableNotification) {
        $Message = New-Object System.Net.Mail.MailMessage $EmailFrom, $EmailTo
        $Message.Subject = $EmailSubject + " - FAILED"
        $Message.IsBodyHTML = $True
        $message.Body = "The backup job failed to run because we could not contact the $HostName vcenter instnace."
        $SMTP = New-Object Net.Mail.SmtpClient($SMTPServer)
        $SMTP.Send($Message)
    }
    exit 1
}
Write-Host "Connected to vCenter server. Getting a list of VMs."

# Get a list of the the VM names based off the location. 
$VMNames = Get-VM -Location $LocationName -Server $HostName
Write-Host "Found a total of $($VMNames.Length) VMs to backup."

# Create a backup and log it. 
foreach ($VMName in $VMNames){
    Write-Host "Backing up ($($VMNames.IndexOf($VMName)+1) of $($VMNames.Length)): $VMName"
    $VM = Find-VBRViEntity -Name $VMName -Server $Server
    $ZIPSession = Start-VBRZip -Entity $VM -Folder $Directory -Compression $CompressionLevel -DisableQuiesce:(!$EnableQuiescence) -AutoDelete $Retention
    If ($EnableNotification){
        $TaskSessions = $ZIPSession.GetTaskSessions()
        $FailedSessions = $TaskSessions | where {$_.status -eq “EWarning” -or $_.Status -eq “EFailed”}
        if ($FailedSessions -ne $Null){
            $FailureCount = $FailureCount + 1
            $mbody = $mbody + ($ZIPSession | Select-Object @{n=”Name”;e={($_.name).Substring(0, $_.name.LastIndexOf(“(“))}} ,@{n=”Start Time”;e={$_.CreationTime}},@{n=”End Time”;e={$_.EndTime}},Result,@{n=”Details”;e={$FailedSessions.Title}})} 
        Else {
            $mbody = $mbody + ($ZIPSession | Select-Object @{n=”Name”;e={($_.name).Substring(0, $_.name.LastIndexOf(“(“))}} ,@{n=”Start Time”;e={$_.CreationTime}},@{n=”End Time”;e={$_.EndTime}},Result,@{n=”Details”;e={($TaskSessions | sort creationtime -Descending | select -first 1).Title}})}
    }
}

# Get a Valid Time
$end = Get-Date
$timespan = new-timespan -seconds $(($end-$start).totalseconds)
$ElapsedTime = '{0:00}h:{1:00}m:{2:00}s' -f $timespan.Hours,$timespan.Minutes,$timespan.Seconds

#Craft an email
If ($EnableNotification) {
    $msummary = "Backup Job Summary:<br />"
    $msummary = $msummary + "$($VMNames.Length) VMs ($FailureCount Warn/Fail) backups from the $HostName vcenter instance.<br />"
    $msummary = $msummary + "Total backup time was: $ElapsedTime<br />"
    If ($EnableEncryption) { $msummary = $msummary + "The backups were encrypted." }
    $msummary = $msummary + "Backups are scheduled to be deleted: $Retention<br /><br />"
    $mbody = Get-VM -Server $HostName -Location $LocationName
    $mbody = $mbody | ConvertTo-Html -head $style | Out-String
    $Message = New-Object System.Net.Mail.MailMessage $EmailFrom, $EmailTo
    $Message.Subject = $EmailSubject
    $Message.IsBodyHTML = $True
    $message.Body = $msummary + $mbody
    $SMTP = New-Object Net.Mail.SmtpClient($SMTPServer)
    $SMTP.Send($Message)
}
