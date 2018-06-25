Function Get-Uptime { 

<#
.SYNOPSIS
Gets the uptime for a local or remote computer.

.DESCRIPTION
The Get-Uptime function gets the uptime for specified computers by retrieving the LastBootUpTime from Win32_OperatingSystem WMI class. The uptime period is calculated in days by comparing the interval between the LastBootUpTime and the current date and time. 

The function sends an Internet Control Message Protocol (ICMP) echo request packet to determine if a the specified computer may be contacted. If the computer is offline this will report a status of 'Offline. If an echo reponse is received, the uptime status will
be determined for the specified computer. If the uptime interval may not be calculated this will report a status of 'Error'.

The function also uses conditional logic to determine if the computer may require patching by determing of the uptime status is greater than 30 days to which the value will be set to 'True'.

.PARAMETER ComputerName 
Specify the computers to retrieve uptime. The default is the local computer. 

.EXAMPLE
PS C:> Get-Uptime 
This command retrieves the uptime for the local computer.

.EXAMPLE 
PS C:> Get-Uptime -ComputerName SERVER1, SERVER2, SERVER3 
This command retrieves the uptime for the computers SERVER1, SERVER2 and SERVER3. 

.INPUTS
System.String
poweersh
You can pipe a computer name to Get-Uptime

.OUTPUTS
System.Management.Automation.PSCustomObject

.NOTES 
Author:            Dean Grant
Date:              Thursday, 4th February 2016
Version:           1.0

.LINK  
Online Version: https://github.com/dean1609/PowerShell/blob/master/ScriptingGames/Get-Uptime.ps1
Blog: 
Scripting Games Puzzle: http://powershell.org/wp/2016/01/02/january-2016-scripting-games-puzzle/ 
#>

[CmdletBinding()]
Param (
    [Parameter(ValueFromPipeline = $True)] [String[]] $ComputerName = $env:COMPUTERNAME
    )

Begin
    {
    # Retrives the current date and time to use as a timespan object. 
    $Date = Get-Date 
    } # Begin

Process
    {
    # Performs an action on each object in the collection. 
    ForEach ($Computer in $ComputerName)
        {
        # Create ordered properties to be used for the custom object. 
        $Output = [Ordered]@{
					'ComputerName' = $Computer
					'StartTime' = $null
					'Uptime (Days)' = $null
					'Status' = $null
					'MightNeedPatched' = $False
				    }
        # Conditional logic to determine if specified computer can be contacted. 
        If (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)
            {
            Try
                {
                # Retrieves information from the Win32_OperatingSystem class for the specified computer. 
                $WmiObject = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer
                # Converts LastBootUpTime property value using ConvertToDateTime() method. 
                $Output.StartTime = $WmiObject.ConverttoDateTime($WMIObject.LastBootUpTime)
                # Creates timespan object to represent time interval between LastBootUpTime and now.
                $Timespan = New-TimeSpan -Start ($Output.StartTime) -End ($Date)
                $Output.'Uptime (Days)' = [Math]::Round($TimeSpan.TotalDays,2)
                # Sets the status to 'OK' as the computer may be contacted.
                $Output.Status = "OK"
                # Conditional logic to determine if the interval between LastBootUpTime and now is greater than 30 days and set patch status. 
                $Output.MightNeedPatched = If ($Timespan -gt "30"){$True}Else{$False}
                } # Try
            Catch
                {
                # Declares non-terminating error if unable to determine the uptime for the specified computer and sets the computer status to 'Error'.
                Write-Error ("Unable to determine uptime for the computer '$Computer', with the error exception: " + $_.Exception.Message + ".")
                $Output.Status = "Error"
                } # Catch  
            } # If
        Else
            {
            # Declares non-terminating error if unable to contact the speficied computer and sets the computer status to 'Offline'.
            Write-Error "Connection to the computer '$Computer' failed. Unable to contact the specified computer."
            $Output.Status = "Offline"
            } # Else  
        # Outputs custom object to display results.
        [PsCustomObject]$Output
        } # ForEach  
    } # Process 
    
End 
    {
     
    } # End  

} # Function