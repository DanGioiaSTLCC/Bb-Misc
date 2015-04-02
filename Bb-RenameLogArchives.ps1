####################################################################
<# Description:
		This script processes the logs\archive directory in a Learn
		application server and renames the archive files from Unix
		epoch timestamps to human readable and host specifc file
		names.
#>
####################################################################
####################################################################
# Script Parameters:
	# none
####################################################################
# ######## Configuration ###########################################
$strBbHome = $env:BLACKBOARD_HOME
$ServerName = $env:COMPUTERNAME
####################################################################

# enumerate archive files to rename
get-childitem -path $strBbHome\logs\archives -filter "*_bblogs.zip" | 
ForEach-Object{ 
	$oldFilePath = $_.FullName
	$oldFileName = $_.Name
	# separate timestamp from name
	$uxTimeStamp = $oldFileName.Split('_')[0]
	# convert timestamp 
	$epochSeconds = $uxTimeStamp / 1000
	$objTime = [TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($epochSeconds))
	$newTimeStamp = get-date $objTime -uFormat %Y-%m-%d_%H
	# build new filename
	$newFileName = "BbAppArchive-$ServerName-$newTimeStamp.zip"
	
	rename-item -path $oldFilePath -newname $newFileName
}

# eof
