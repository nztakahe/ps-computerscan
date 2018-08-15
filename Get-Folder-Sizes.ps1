<#
.SYNOPSIS
Script that will list folders and files sizes recursively.
.DESCRIPTION
** This script will list folders/files sizes recursively to a specified level or files at the specified level.
** You can use it to find specific file type (such as mp4, mp3 or pdf files) recursively or at specific level 
** (eg. c:\users\user2\* only). You can also find files from the starting directory to a specific directory level  
** (eg. from c:\* to c:\users\user2\*). You can find the sum of specific files type under that directory (eg. 
** all *.exe files under c:\users\* directory), which will show output as their parent folder sizes.
** If the -Directory parameter is not specified or doesn't exist, the current directory is used. And -Level 
** and -ToLevel parameters will refer to child levels from that existing directory. Find more about parameters
** in parameter section.
Example usage:																					  
.\Get_Folder_Sizes -Directory c:\users -level 2 -Display
.\Get_Folder_Sizes -Directory c:\users -level 2 -FileOnly
.\Get_Folder_Sizes -Directory C:\Windows\System32 -level 1 -FileType exe
Author: phyoepaing3.142@gmail.com
Country: Myanmar(Burma)
Released: 11/12/2016
*** Changed History ***
11/12/2016 - version 1.0 - Initial released.
04/17/2017 - version 1.1 - change the filesize property from string type to decimal type. You can now sort the folder sizes.
.EXAMPLE
.\Get_Folder_Sizes -level 2 -Display
It will list folder sizes up to 2 level from current directory. It will turn on Stretch view
for easy viewing.
.EXAMPLE
.\Get_Folder_Sizes -Directory c:\users -level 2 -FileOnly
It will list all files only at child level 2 from c:\users.
.EXAMPLE
.\Get_Folder_Sizes -Directory c:\users -ToLevel 3 -FileOnly
It will list all files from c:\users directory up to 3 levels of it's child directories.
.EXAMPLE
.\Get_Folder_Sizes -Directory C:\Windows\System32 -level 1 -FileType exe
It will list the total size of folders under c:\Windows\System32, couting only *.exe file type.
.PARAMETER Directory
Specify the directory from which file/folder level count starts. We can call it root directory.
.PARAMETER Level
Specify the number of levels to include from current directory or directory specified in -Directory 
Parameter. Eg. if the current directory is c:\users then, -Level 2 refers to c:\users\*\*. In listing
folders, it includes all directories under the root directory. In listing files, it refers to only
the directory level from the root directory.
.PARAMETER ToLevel
Specify the number of levels to include from root directory. This parameter is only valid for listing 
files. It will include all files between the root directory and that child directory.
.PARAMETER FileOnly
It will list only files sizes instead of folder sizes.
.PARAMETER FileType
Specify the filetype to include in your folder/file size listings. You need to use file extension without 
dot for this. Eg, -FileType mp4
.PARAMETER Display
It will display the folders' fullpath with sizes in stretch format (with guided lines) for easy view.
.LINK
You can find this script and more at: https://www.sysadminplus.blogspot.com/
#>

param( [Parameter(Mandatory=$False,Position=1)][string]$Directory,[int]$level,[int]$ToLevel,[switch]$FileOnly,[string]$FileType,[switch]$display)
#########################################################################################
############## Function to retrieve directory with recursive function call #############
function Get-Directory ($fullname,$D_ChildLevel,$FileType)  { 
If($fullname.Split('\').Length -le $D_ChildLevel -OR !$level )
	{
	If($FileType)			## if filetype is specified, then only output the folder size of specific files sum
	{
	$size_sum = (Get-ChildItem -R $fullname -File -Filter *.$FileType -EA SilentlyContinue -ErrorVariable ProcessError | measure -Property Length -Sum).sum
	}
	else
	{
	$size_sum = (Get-ChildItem -R $fullname -File -EA SilentlyContinue -ErrorVariable ProcessError | measure -Property Length -Sum).sum
	}
		
	$dot= $null;$line= 100 - $fullname.Length ; 
	0..$line | foreach { $dot+='-' } ; 

	$obj= "" | select DirectoryPath,'FolderSize(KB)','FolderSize(MB)','FolderSize(GB)'; 
		If ($display)
			{
			$obj.DirectoryPath="$fullname   $dot"; 
			}
		else
			{
			$obj.DirectoryPath=$fullname; 
			}
		$obj.'FolderSize(KB)'=[decimal]"$( [math]::round($size_sum/1KB,2))" ; 
		$obj.'FolderSize(MB)'=[decimal]"$( [math]::round($size_sum/1MB,2))" ; 
		$obj.'FolderSize(GB)'=[decimal]"$( [math]::round($size_sum/1GB,2))" ; 

############## Recall the function if the current directory is the directory itself ############33
	if ((gi $fullname) -is [system.io.directoryinfo] )
		{  $i= $fullname.split('\').length+1 ; 
			Get-ChildItem $fullname -directory -EA SilentlyContinue -ErrorVariable ChildProcess | foreach { 
			Get-Directory $_.fullname $D_ChildLevel $FileType
			} 
		If(!$ChildProcess)
		{ 
		return $Obj 
		}
	} 

############## if the error variable is set, then output the error ###########
	If ($ProcessError)
		{
		$ProcessError | foreach { write-host -fore red $_ | select-string 'is denied'}
		}	
	}
}

################################################################################
############## Function to retrieve file with their sizes ######################
function Get-File ([string]$Directory,[int]$F_ChildLevel,[int]$TotalChildLevel) {
If ($FileType)
	{
	1..$F_ChildLevel | foreach {
		If($F_ChildLevel -eq 1)
		{
		$Depth +="\*.$FileType";
		$FileTypeAppended = $True
		}
		else
		{
		$Depth +='\*';
		}
	}
	If (!$FileTypeAppended )  { $Depth +="."+$FileType }  ## If filetype is already appended, then skip the next file append to $Depth Wildcard
	}													## If filetype is not defined, then only specify the level to search such as c:\myfolder\*\*
else													
	{
	1..$F_ChildLevel | foreach { 
	$Depth +='\*';
	}
	}
$DirectoryWildCard = $Directory.TrimEnd('\').Trim()+$Depth	## Make the search pattern for searching files with Get-ChildItem

############## If user does not define the level parameter, then retrieve all files or specific files as defined ####################3
If (($F_ChildLevel -eq 0) -AND !$TotalChildLevel)
	{
############## If file type is defined but not level, then retrieve all files of specific file type ######################
		If($FileType)
		{
		Get-ChildItem $Directory -R -File -Filter *.$FileType -EA SilentlyContinue -ErrorVariable ProcessError | select @{N='FilePath';Exp={$_.FullName}}, @{N='FileSize(KB)';Exp={[math]::round($_.Length/1KB,2)}},
		@{N='FileSize(MB)';Exp={[math]::round($_.Length/1MB,2)}}, @{N='FileSize(GB)';Exp={[math]::round($_.Length/1GB,2)}}
############## If errors occurs while accessing files, then output the error variable ##################################
		If($ProcessError)
		{ $ProcessError | foreach { write-host -fore red $_ | select-string 'is denied'} }
		}
		else
		{
############## if file type is not defined, then retrieve all files recursively #######################
		Get-ChildItem $Directory -R -File | select @{N='FilePath';Exp={$_.FullName}}, @{N='FileSize(KB)';Exp={[math]::round($_.Length/1KB,2)}},
		@{N='FileSize(MB)';Exp={[math]::round($_.Length/1MB,2)}}, @{N='FileSize(GB)';Exp={[math]::round($_.Length/1GB,2)}}
		}
	}
	elseif ($FileType -AND $TotalChildLevel)     ## If the user define FileType & ToLevel parameter, then filter only files up to specific level ########
	{
		Get-ChildItem $Directory -R -File -Filter *.$FileType -EA SilentlyContinue -ErrorVariable ProcessError | foreach {  
			if($_.FullName.Split('\').Length -le $TotalChildLevel ) 
				{
				$obj= "" | select DirectoryPath,'FileSize(KB)','FileSize(MB)','FileSize(GB)';
				$obj.DirectoryPath = $_.fullname
				$obj.'FileSize(KB)'=[decimal]"$( [math]::round($_.Length/1KB,2))" ; 
				$obj.'FileSize(MB)'=[decimal]"$( [math]::round($_.Length/1MB,2))" ; 
				$obj.'FileSize(GB)'=[decimal]"$( [math]::round($_.Length/1GB,2))" ;
				$obj;
				}  
		}
	If($ProcessError)
		{
		$ProcessError | foreach { write-host -fore red $_ | select-string 'is denied'}
		}
	}
	
############ If the user defined ToLevel parameter & then include all files to specified depth ########
	elseif ($TotalChildLevel)
	{
		Get-ChildItem $Directory -R -File -EA SilentlyContinue -ErrorVariable ProcessError | foreach {  
			if($_.FullName.Split('\').Length -le $TotalChildLevel ) 
				{
				$obj= "" | select DirectoryPath,'FileSize(KB)','FileSize(MB)','FileSize(GB)';
				$obj.DirectoryPath = $_.fullname
				$obj.'FileSize(KB)'=[decimal]"$( [math]::round($_.Length/1KB,2))" ; 
				$obj.'FileSize(MB)'=[decimal]"$( [math]::round($_.Length/1MB,2))" ; 
				$obj.'FileSize(GB)'=[decimal]"$( [math]::round($_.Length/1GB,2))" ;
				$obj;
				}  
		}
		If($ProcessError)
		{
		$ProcessError | foreach { write-host -fore red $_ | select-string 'is denied'}
		}
	}	
else
	{
############# if file type flag is set & specific level only is defined, then search for files at specified level ############
	Get-ChildItem $DirectoryWildCard -File | select @{N='FilePath';Exp={$_.FullName}}, @{N='FileSize(KB)';Exp={[math]::round($_.Length/1KB,2)}},
	@{N='FileSize(MB)';Exp={[math]::round($_.Length/1MB,2)}}, @{N='FileSize(GB)';Exp={[math]::round($_.Length/1GB,2)}}
	}
}

#####################################################################################################################################################################################
############### If the start directory is defined & if it exists then use the start directory & that directory's level, if not use the current directory & current level ############
If ($Directory -AND (Test-Path $Directory))
	{
############### If the user directory input is does not contain back slash such as c:, then put the back slash ###########
		If ($Directory -Notmatch '\\' -AND (Test-Path $Directory))
		{ $Directory  = $Directory+'\' }
############### If the directory input doesn't contains extra backslash such as c:\windows\, then increase $CurrentLevel value by one
		If ( ($Directory.Split('\') | unique)[($Directory.Split('\') | unique).Length-1].Length -eq 0 )
			{
			write-Debug "extra slash statement executed."
			$CurrentLevel = ($Directory.Split('\') | unique).Length
			}
		else
			{
			write-Debug "WITHOUT extra slash statement executed."
			$CurrentLevel = $Directory.Split('\').Length + 1
			}
	}
else
	{
	Write-Host -fore yellow "The specified directory does not exist. Using current directory as default starting directory."
		If ((Get-Location).Path.Split('\')[1].Length -eq 0)		## If the current directory is root Drive itself, then use the split length directly, if not, use length+1 for $CurrentLevel
			{
			$CurrentLevel = (Get-Location).Path.Split('\').Length
			}
		else
			{
			$CurrentLevel = (Get-Location).Path.Split('\').Length + 1
			}
	$Directory = Get-Location
	}
################ If $Level is not defined, then recurse through all directories ##########
If([int]$Level)
	{
	$TotalChildLevel = $CurrentLevel + $Level - 1			## add current level + child level, so that we can check fullpath and ignore if path is longer than defined in functions.
	}
If($FileOnly -AND $ToLevel)
	{
	$TotalChildLevel = $CurrentLevel + $ToLevel - 1			## For file listings, add current level + ToLevel to find the total level so that we can ignore when the fullpath is longer than defined.
	Get-File $Directory $Level $TotalChildLevel
	}
elseIf ($FileOnly)											## FileOnly parameter is set, then list only files at the specific level only
	{
	Get-File $Directory $Level
	}
elseif ($FileType)											## If Filetype parameter is set, call the function with specified file type
	{
	Get-ChildItem $Directory -directory | foreach { $i = $_.fullname.split('\').length;
	Get-Directory $_.fullname $TotalChildLevel $FileType}
	Write-Host -fore yellow "Only the total size of folders with the sum of *.$FileType files' size are included.`n"
	}
elseif ($Directory -AND $ToLevel)							## If ToLevel option is defined, then exit the script
	{
	Write-Host -fore red "It is Not a valid option to use 'ToLevel' parameter for Directory listing."
	}
else														## If not everyting specified, then call directory listing function 
	{
	Get-ChildItem $Directory -directory | foreach { $i = $_.fullname.split('\').length;
	Get-Directory $_.fullname $TotalChildLevel}    
	}