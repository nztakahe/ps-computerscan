[CmdletBinding()]
Param (
    [Parameter(ValueFromPipeline = $True)] [String[]] $ComputerName = $env:COMPUTERNAME
    )

# Parts hacked from 
# https://gallery.technet.microsoft.com/scriptcenter/Powershell-Query-a-patch-67cf35f8
# https://gallery.technet.microsoft.com/Invoke-All-Generic-script-9287c7cd#content

# TODO: Convert to loadable module

Set-StrictMode -Version Latest
#TODO: Debug Messages configured by param\environment
$DebugPreference = "Continue"

#Unique file name for each run
[String]$Script:Logfilename = "InvokeAll_$(Get-Date -format "yyyyMMdd_HHmmss").log"
$Script:Logfile = $NULL


#logging function
#Create a new log file for each run, if file is already present, append it.
function Write-Log
{
[CmdletBinding()] 
    Param 
    (
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()] 
        [String]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateScript({ Test-Path "$_" })]
        [string]$LogPath= "$($PSScriptRoot)"
        
    )
	#If Logfile is not created yet, create one. This script uses the ScriptRoot directory by default
    if(-not $Script:Logfile){

        $LogPath = $LogPath.TrimEnd("\")
        if(Test-Path "$LogPath\$Script:Logfilename"){
            $Script:LogFile = "$LogPath\$Script:Logfilename"
        
        }Else{
            $Script:LogFile = New-Item -Name "$Script:Logfilename" -Path $LogPath -Force -ItemType File
            Write-Verbose "Created New log file $Script:LogFile"
        }
    }
    
    $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Verbose "[$FormattedDate] $Message"
    "[$FormattedDate] $Message" | Out-File -FilePath $LogFile -Append    
}



Function Get-UpTime  
{  
    param([string] $LastBootTime)
    $Uptime = (Get-Date) - [System.Management.ManagementDateTimeconverter]::ToDateTime($LastBootTime)  
    # "Days: $($Uptime.Days); Hours: $($Uptime.Hours); Minutes: $($Uptime.Minutes); Seconds: $($Uptime.Seconds)"
    return $Uptime
}  

Function Ping{
    param([string] $Computer)
    Write-Debug ("Starting Ping $Computer")
    [System.Management.ManagementObject] $ping = Get-WmiObject -Query "Select * from win32_PingStatus where Address='$Computer'"
    return $ping
}

Function Get-PingStatusCode
{   
    Param([int] $StatusCode)    
    switch($StatusCode)  
    {  
        0         {"Success"}  
        11001   {"Buffer Too Small"}  
        11002   {"Destination Net Unreachable"}  
        11003   {"Destination Host Unreachable"}  
        11004   {"Destination Protocol Unreachable"}  
        11005   {"Destination Port Unreachable"}  
        11006   {"No Resources"}  
        11007   {"Bad Option"}  
        11008   {"Hardware Error"}  
        11009   {"Packet Too Big"}  
        11010   {"Request Timed Out"}  
        11011   {"Bad Request"}  
        11012   {"Bad Route"}  
        11013   {"TimeToLive Expired Transit"}  
        11014   {"TimeToLive Expired Reassembly"}  
        11015   {"Parameter Problem"}  
        11016   {"Source Quench"}  
        11017   {"Option Too Big"}  
        11018   {"Bad Destination"}  
        11032   {"Negotiating IPSEC"}  
        11050   {"General Failure"}  
        default {"Failed"}  
    }  
}  


Function main{
(Param [string] $ComputerName)

    Write-Debug("Started Scan for $ComputerName")

    #Ping Computer
    [System.Management.ManagementObject] $p = ping($ComputerName)

    if ($p.StatusCode -eq 0){
        Write-Debug("Do more scanning.")
        [System.Management.ManagementObject] $OS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName  
        [string] $OSRunning = $OS.caption + " " + $OS.OSArchitecture + " SP " + $OS.ServicePackMajorVersion 
        [System.TimeSpan] $uptime = Get-UpTime($OS.LastBootUpTime)
    } else {
        Write-Debug("GetStatusCode returned $Status")
    }
    Write-Debug('Main Finished')
}

$r = main($ComputerName)


