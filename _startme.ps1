#Store Starting Directory
[System.Management.Automation.PathInfo] $startdir = Get-Location

[String] $scriptroot = $PSScriptRoot
Set-Location -Path $scriptroot
Import-Module .\invokeallV2.5.ps1
Import-Module .\getuptime.ps1

Get-Content -Path .\computers.txt | Invoke-All {Get-Uptime} -WaitTimeOut 1000| Format-Table


#Change to Starting Directory
#Set-Location -Path $startdir.Path

#Set-Location -Path
# Import-Module 
# Get-Content -Path .\computers.txt