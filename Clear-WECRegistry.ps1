<#

.SYNOPSIS
Removes clients from WEC registry for clients that have not checked in for 7 days.

.DESCRIPTION
Intended to be ran weekly, inspects the WEF subscription registry and collects all client names.
If the LastHeartbeatTime is > 7 days old, or does not exist the entry will be removed from the 
registry.

.PARAMETER EnableLog
Enables the creation of a log file, records the list of clients removed from registry.

.EXAMPLE
PS > ./Clear-WECRegistry.ps1
PS > ./Clear-WECRegistry.ps1 -EnableLog

#>
Param([Switch]$EnableLog)

if($EnableLog){
    $FormattedDate = Get-Date -Format "yyyy-MM-dd-HHmm"
    $LogFile = "WEC_Stale_Clients_$FormattedDate.log"
    if((Test-Path -Path $LogFile) -eq $false){
        New-Item -Path $LogFile -ItemType File
    }
}

#Writes output to a log file
function Write-Log(){
    Param(
        [String]$message,
        [String]$level,
        [String]$CurrentPath
    )

    if($level -eq "WARN"){
        $LogMessage = "WARN: $message`nWARN: Removed stale client at $CurrentPath"
    }
    elseif($level -eq "ERROR"){
        $LogMessage = "ERROR: $message"
    }
    else{
        $LogMessage = "INFO: Removed stale client at $CurrentPath"
    }
    #Only write to log if file is created, else write to verbose stream
    if($EnableLog){
        Add-Content $LogFile -Value $LogMessage
    }
    else{
        Write-Verbose $LogMessage
    }
}

#Removes the specified WEF client subkey
function Remove-Key(){
    Param(
        [String]$Path
    ) 
    if(Test-Path -Path $Path){
        Remove-Item -Path $Path -Force
    }
}

#Get timestamp
$ServerTime = ((Get-Date).AddDays(-7)).ToFileTime()

#For each subscription EventSource in HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\EventCollector\Subscriptions
#Get SubKey Path and compare LastHeartbeatTime to local server time
$keys = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\EventCollector\Subscriptions\*\EventSources -Recurse | Select-Object -ExpandProperty PSPath
foreach($key in $keys){
    $Action=0
    try{
        $HeartbeatTime = Get-ItemPropertyValue $key -Name LastHeartbeatTime -ErrorAction Stop
    }
    catch{
        $Action=1
        if($_.Exception.Message -like "Property LastHeartbeatTime does not exist at path*"){
            Remove-Key $key
            Write-Log "$_.Exception.Message" "WARN" "$key"
        }
        else{
        	Write-Log "$_.Exception.Message" "ERROR" "$key"
        }
    }
    #If LastHeartbeat > 7 days old remove client SubKey
    if($Action -eq 0){
        if($HeartbeatTime -le $ServerTime){
            Remove-Key $key
            Write-Log "Removed key." "INFO" "$key"
        }
    }
}
