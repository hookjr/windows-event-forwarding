<#

.SYNOPSIS
Checks health of Windows Event Collector core components: wecsvc, subscriptions, and source registry

.DESCRIPTION
Intended to run as a service or task. Logs failure messages to be consumed and acted on.

Event Log: Application
Event Source: WECHealthCheck
Event IDs:
    __ID__   ___TYPE___      ___OVERVIEW___
    * 3001 - Failure Audit - Generated when WEC Service (wecsvc) is not running.
    * 3002 - Failure Audit - Generated when service attempts to restart but fails.
    * 3003 - Failure Audit - Generated when no subscriptions are loaded or active.
    * 3004 - Informational - Generated when -gt 10,000 source hosts are in registry.
    * 3005 - Warning       - Generated when -gt 20,000 source hosts are in registry. Potential performance impact.

.PARAMETER Autofix
Enables optional functions to attempt to restart wecsvc if stopped, and load subscriptions if not loaded.

.PARAMETER SubscriptionPath
Local file path to subscription XML. By default set to C:\Subscriptions$

.EXAMPLE
PS > ./Test-WECStatus.ps1
PS > ./Test-WECStatus.ps1 -Autofix -SubscriptionPath C:\Path\to\Subscriptions.xml

#>

Param(
[Switch]$Autofix,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[String]$SubscriptionPath
)

if(!$SubscriptionPath){
    $SubscriptionPath = "C:\Subscriptions`$"
}

<#
.SYNOPSIS
    Tests for active subscriptions. 
    
    if $Autofix = $true
    Attempts to load subscriptions from disk if none found.
#>
function Test-WECSubscription{
    if((& "wecutil.exe" @("es")).length -eq 0){
        Write-EventLog -LogName "Application" -Source "WECHealthCheck" -EventID 3003 -EntryType FailureAudit -Message "Windows Event Collector health: No valid subscriptions loaded."
        if($Autofix){
            (Get-ChildItem -Path C:\Subscriptions$ -Filter *.xml).FullName | ForEach-Object{& "wecutil.exe" @("cs","$_") }
        }
        else{
            return $false
        }
    }
    else{
        return $true
    }
}

<#
.SYNOPSIS
    Tests for running service wecsvc. 
    
    if $Autofix = $true
    Attempts to start service if stopped.
#>
function Test-WECService{
    if(Get-Service -Name "wecsvc" | Where-Object {$_.Status -ne "Running"}){
        Write-EventLog -LogName "Application" -Source "WECHealthCheck" -EventID 3001 -EntryType FailureAudit -Message "Windows Event Collector health: Service is not running."
        if($Autofix){
            try{
                Start-Service -Name "wecsvc" -ErrorAction Stop
            }
            catch{
                Write-EventLog -LogName "Application" -Source "WECHealthCheck" -EventID 3002 -EntryType FailureAudit -Message "Windows Event Collector health: Service failed to start."
                return $false
            }
        }
        else{
            return $false
        }
    }
    else{
        return $true
    }
}

<#
.SYNOPSIS
    Tests size of EventSources registry.
#>
function Test-WECRegistry{
    $sources = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\EventCollector\Subscriptions\*\EventSources -Recurse | Select-Object -ExpandProperty PSPath
    if(($sources | Measure-Object).count -gt 10000){
        Write-EventLog -LogName "Application" -Source "WECHealthCheck" -EventID 3004 -EntryType Informational -Message "Windows Event Collector health: Source registry exceeds 10,000 hosts."
    }
    if(($sources | Measure-Object).count -gt 20000){
        Write-EventLog -LogName "Application" -Source "WECHealthCheck" -EventID 3005 -EntryType Warning -Message "Windows Event Collector health: Source registry exceeds 20,000 hosts. Collector performance may be diminished."
    }
}

# Register Event Source
try{
    New-EventLog -Source WECHealthCheck -LogName Application -ErrorAction Stop
}
catch [System.InvalidOperationException]{
    Write-Debug "Event Log source already exists. Continuing operation." 
}
# Run health check functions.
finally{
    Test-WECService
    Test-WECSubscription
    Test-WECRegistry
}
