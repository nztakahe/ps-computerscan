Function Get-ComputerScan
{
<#
    #TODO Add some Documentation
#>

[CmdletBinding()]
Param (
    [Parameter(ValueFromPipeline = $True)] [String[]] $ComputerName = $env:COMPUTERNAME
    )

Begin
    {
    # Keep me Honest
	Set-StrictMode -Version 1
    write-debug("Processing $ComputerName")
	#Timer to keep track of time spent on each section
	$Timer = [system.diagnostics.stopwatch]::StartNew()
    $Timer.Start()

    Function Get-UpTime  
    {  
        param([string] $LastBootTime)
        $Uptime = (Get-Date) - [System.Management.ManagementDateTimeconverter]::ToDateTime($LastBootTime)  
        # "Days: $($Uptime.Days); Hours: $($Uptime.Hours); Minutes: $($Uptime.Minutes); Seconds: $($Uptime.Seconds)"
        return $Uptime
    } # Function Get-UpTime

    Function Ping{
        param([string] $Computer)
        Write-Debug ("Starting Ping $Computer")
        [System.Management.ManagementObject] $ping = Get-WmiObject -Query "Select * from win32_PingStatus where Address='$Computer'"
        return $ping
    } # Function Ping

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
        }  # End Switch
    }  # Function Get-PingStatusCode

    
    } # Begin
Process
    {
    ForEach ($Computer in $ComputerName)
        {
        # Create ordered properties to be used for the custom object. 
        $Output = [Ordered]@{
					'ComputerName' = $Computer
					'Scantime' = $null
					'StartTime' = $null
					'Uptime' = $null
					'Status' = $null
				    }
        # Ping
        [System.Management.ManagementObject] $p = ping($ComputerName)

        if ($p.StatusCode -eq 0){
            Write-Debug("Ping Worked")

            [System.Management.ManagementObject] $OS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName  
            [string] $OSRunning = $OS.caption + " " + $OS.OSArchitecture + " SP " + $OS.ServicePackMajorVersion 
            $Output.ScanTime = Get-Date
            $Output.StartTime = $OS.LastBootUpTime
            $Output.uptime = Get-UpTime($OS.LastBootUpTime)
        } else {
            if ($p.StatusCode -eq  $null ){
                #ToDo: Check if there is a more elligent check
                Write-Debug('Ping failed to resolve?')
                $Output.Status = "Ping - Unresolved"
            } else {
                [string] $PingStatus = Get-PingStatusCode($p.StatusCode)
                $Output.Status = "Ping - Code: $($p.StatusCode).  Desc. $PingStatus "
            }
        }

        [PsCustomObject]$Output
    } # ForEach
} # Process 
    
End 
    {
        $Timer.Stop()
 		Write-Debug("Time took to Invoke and Complete the Jobs : $($Timer.Elapsed.ToString())")
     
    } # End  

} # Function


#Testing Get-ComputerScan -ComputerName "doesnotexist"