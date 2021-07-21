# windows-event-forwarding

## Overview
>Windows Event Forwarding (WEF) reads any operational or administrative event log on a device in your organization and forwards the events you choose to a Windows Event Collector (WEC) server.<sup>[1]

### Objectives

1. Centralize Logging
   - Move all agents to Event Collector servers
2. Improve Flexibility of Logging
   - Target specific EventIDs via Subscriptions
3. Promote Future Enhancements on Existing Infrastructure
   - Custom event channels
   - Flexibility to install new agents on purpose built Event Collectors
4. Significtantly Reduce Overhead
   - Work effort focused on Event Collectors, no need to maintain agents on all servers

## Subscriptions
Subscriptions define the events that will be forwarded by clients connecting to the event collectors. A baseline subscription, intended to capture high fidelity but low bandwidth rules, is added to each collector. Targeted subscriptions are placed on relevant event collectors.

### General
- Baseline.xml

### Workstations
- Workstations.xml

### Servers
- MemberServers.xml
- DomainControllers.xml

## Management

### Installed Agents
Agents are installed on the event collector servers only.

### Winlogbeat

## Appendix

### Terminology

#### Clients
Anything sending event logs to a collector server, including servers and end user computers.

#### Collectors
Servers that receive forwarded events from clients.

- WEC (Windows Event Collectors)
- Event Collectors
- Collector server

### References

#### Microsoft
- https://docs.microsoft.com/en-us/windows/security/threat-protection/use-windows-event-forwarding-to-assist-in-intrusion-detection
- https://docs.microsoft.com/en-us/archive/blogs/jepayne/weffles
- https://docs.microsoft.com/en-us/archive/blogs/jepayne/monitoring-what-matters-windows-event-forwarding-for-everyone-even-if-you-already-have-a-siem

[1]: https://docs.microsoft.com/en-us/windows/security/threat-protection/use-windows-event-forwarding-to-assist-in-intrusion-detection
[2]: https://docs.microsoft.com/en-us/windows/security/threat-protection/use-windows-event-forwarding-to-assist-in-intrusion-detection#appendix-d---minimum-gpo-for-wef-client-configuration
[3]: https://docs.microsoft.com/en-us/windows/security/threat-protection/use-windows-event-forwarding-to-assist-in-intrusion-detection#appendix-e--annotated-baseline-subscription-event-query

#### Palantir
- https://github.com/palantir/windows-event-forwarding
- https://medium.com/palantir/windows-event-forwarding-for-network-defense-cb208d5ff86f

#### NSA Cyber
- https://github.com/nsacyber/Event-Forwarding-Guidance****


# WEF Deployment Guide

## Table of Contents
1. Event Collectors
   - Configuration
   - Installs
   - Support

## Event Collectors

### Configuration

1. Enable WinRM
```
Set-Service -Name winrm -StartupType Automatic
winrm quickconfig -quiet
```
2. Increase Forwarded Events log size to 5GB
```
wevtutil sl forwardedevents /ms:5000000000
```
3. Configure wecutil with quick-config:
   1. Enables the ForwardedEvents channel if it is disabled.
   2. Sets the Windows Event Collector service to delay start.
   3. Start the Windows Event Collector service if it is not running.
```
wecutil qc -quiet
```
4. Set the collector service start automatically
```
Set-Service -Name Wecsvc -StartupType "Automatic"
```

### Installs

#### Winlogbeat
TODO

### Support

#### Registry
Subscriptions adds a registry entry that each applicable client is added as a value under. These do not get automatically cleaned up, and as such they will need to be regularly emptied so they do not get overloaded. They can be manually deleted or the subscription can be removed and re-added via wecutil. 

See also: Clear-WECRegistry.ps1

Key name:
```
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\EventCollector\Subscriptions\<SubscriptionName>
```
