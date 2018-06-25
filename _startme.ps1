#Store Starting Directory
[System.Management.Automation.PathInfo] $startdir = Get-Location

[String] $scriptroot = $PSScriptRoot

#Add Function Librarys
. $PSScriptRoot\invokeallV2.5.ps1
. $PSScriptRoot\ComputerScan.ps1

#. $PSScriptRoot\getuptime.ps1

Get-Content -Path $PSScriptRoot\computers.txt | Invoke-All {Get-ComputerScan} -WaitTimeOut 1000| Format-Table


remove-item function:get-computerscan
remove-item function:invoke-all

#Change to Starting Directory
#Set-Location -Path $startdir.Path

#Set-Location -Path
# Import-Module 
# Get-Content -Path .\computers.txt