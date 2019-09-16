<#
.NOTES 
	Name: ScaleXenAppServers.ps1
	Author: Brian Monroe, Tim Hanson
	License: MIT
	Requires: PowerShell v4 or later, Windows Server 2012 or later
	Version History:
	1.0 - 09/16/2019 - Initial Release
.SYNOPSIS 
	Scales down XenApp servers that are not in use. 
.SYNTAX
	[PS] C:\>.\ScaleXenAppServers.ps1
.DESCRIPTION 
	Checks the servers through the Delivery Controller if there are any sessions 
  on servers and starts to scale them down if it's outside of the production 
  hours you set. First it puts them in Maintanance mode so new sessions do not
  get assigned, then if there are no sessions on the VDA, it shuts them down.
  You need to have power management enabled in the Delivery Controller for the
  script to function properly. This script must be run from the Delivery Controller
  for the farm of the listed servers below.
.RELATED LINKS
	https://www.github.com/azusapacificuniversity/
.EXAMPLE 
	[PS] C:\>.\ScaleXenAppServers.ps1
#>
Asnp Citrix.*

# List of computers to scale up/down
$ServerList = @('EXAMPLE\AWS-XA-1','EXAMPLE\AWS-XA-2','EXAMPLE\AWS-XA-3')

# Schedule Production Times
# This needs to be set in 24hr format (aka military time) so it's 06:00 not 6:00
$ProductionTimeStart = '07:30'
$ProductionTimeEnd = '19:00'

# Schedule Production Days (Days that more servers should be running)
# This would be Weekdays
$ProductionDays = @('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')

# Set SlackNotify to $false to disable notifications
$SlackNotify = $true
# Be sure to also configure message settings below in the Slack-Message section.

# Get the Current Time and Day of the week. 
# TODO: see if I can add error checking for time result.  Email alert if unexpected behavior. ( no time returned )
$time = $(Get-Date -Format HH:mm)
$day = $(Get-Date -Format dddd)

#See if We're running during a scheduled Production time
if ( ( $time -ge $ProductionTimeStart) -and ( $time -lt $ProductionTimeEnd ) -and ($ProductionDays.Contains($day)) ){
    $ProductionHours = $true
}else {
    $ProductionHours = $false
}

# Function and Settings for Slack notifications
function Slack-Message{
    param($SlackTxt)
    $SlackKey = "<Insert your Slack Key>"
    $SlackChan = "<Insert #channel name>"
    $SlackIcon = "<Insert Slack :emoji:>"
    $SlackUrNm = "XenApp Scaling"
    $Payload = @{
	"channel" = $SlackChan
	"icon_emoji" = $SlackIcon
	"text" = "$SlackTxt"
	"username" = $SlackUrNm
    }
    if ($SlackNotify){
        Invoke-WebRequest `
	        -Body (ConvertTo-Json -Compress -InputObject $Payload) `
	        -Method Post `
	        -UseBasicParsing `
	        -Uri "https://hooks.slack.com/services/${SlackKey}" | Out-Null
    }
}


foreach ($Server in $ServerList){
    # TODO: I should also see about adding error checking for this section where information is being gathered on the state of the xenapp nodes.
    # Get server powerstate and maintenance mode state  
    $ServerPower = $(Get-BrokerDesktop -MachineName $Server).PowerState
    $ServerMode = $(Get-BrokerDesktop -MachineName $Server).InMaintenanceMode

    #Get Server's session count.
    $sessions = $(Get-BrokerSession -MachineName $Server)
    $SessionCount = 0
    foreach ($session in $sessions){
        $SessionCount = $SessionCount + 1
    }
    # Check if we should turn on for Production Hours
    if ($ProductionHours){ 
  	    if ($ServerPower -eq 'Off'){
		    New-BrokerHostingPowerAction -MachineName $Server -Action TurnOn
		    Set-BrokerMachineMaintenanceMode -InputObject $Server -MaintenanceMode $false
            Slack-Message "Turned on $Server for production availability."
	    }
    }
    # Since we aren't in Production Hours, we should start scaling down.
    else{
      if ($ServerMode -eq $false){
            # Turn on Maintenance mode to start scaling down.
            Set-BrokerMachineMaintenanceMode -InputObject $Server -MaintenanceMode $True
	    }
	    if (($ServerPower -eq 'On') -and ($SessionCount -eq 0)){
            # Power off if there's no active sessions. 
            New-BrokerHostingPowerAction -MachineName $Server -Action Shutdown
            Slack-Message "Turned off $Server due to inactivity."
      }
    }
}
