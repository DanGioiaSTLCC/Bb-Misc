####################################################################
# Purpose: Manage Bb Logs and Temp Files
#
# Description: Stop Services, Clean temp files, rotate logs, apply updates
#
# This file authored at St. Louis Community College
# dgioia3@stlcc.edu
####################################################################

####################################################################
# Script Parameter(s):
Param(
	[Parameter(Mandatory=$false)][string]$LogArchives=""
)
####################################################################

function GetTimestamp() {
	$strTimestamp = get-date -uFormat %Y-%m-%d_%H.%M.%S
	$strTimestamp = "[" + $strTimestamp + "]"
	return $strTimestamp
}

function LogIt() {
	Param(
		[string]$strLogMsg
	)
	$stamp=GetTimestamp
	add-content -path $strCleanLog -value "$stamp$strLogMsg"
	# Add console output in case of manual execution
	write-host "$stamp$strLogMsg"
}

function FileClean() {
	Param(
		[string]$strFilePath
	)
	LogIt "removing $strFilePath"
	remove-item $strFilePath
}

# setup variables
# ######## Configuration ######################################################
$dtStamp = get-date -uFormat %Y-%m-%d
$strBbHome = $env:BLACKBOARD_HOME
$strCleanLog = "$strBbHome\logs\bb-cleanlog-$dtStamp.txt"
$dtOldest=(get-date).adddays(-7);
# #############################################################################
$intBytesRemoved=0

# Stop Blackboard services
LogIt "stopping Blackboard ..."
cmd /c "$strBbHome\tools\admin\servicecontroller.bat services.stop" | out-file $strCleanLog

# Report patch level
cmd /c "$strBbHome\tools\admin\bbPatch.bat list" |out-file $strCleanLog

LogIt "Cleaning up temp locations ..."
# Cleanup upload temp files
get-childitem -path "$env:blackboard_home\apps\tomcat\temp\*" -include @(".tmp*Tempfile","pluginstoretmp_*.war","*.tmp") | 
	where-object { 
		($_.PSIsContainer -eq $false) -and ($_.LastWriteTime -lt $dtOldest)
	} |
	foreach-object {
		$strFile=$_.FullName;
		$ObjBytes = $_.Length;
		$intBytesRemoved += $ObjBytes;	
		FileClean "$strFile";
	}

# Traverse webapps folders for upload files
get-childitem -path $env:blackboard_home\apps\tomcat\work\Catalina\localhost\webapps_* |
	where-object{ 
		$_.PSIsContainer 
	} | 
	foreach-object {
		$strFolder=$_.Fullname; 
		get-childitem -path "$strFolder\upload__*.tmp"
	}| 
	where-object {
		$_.LastWriteTime -lt $dtOldest
	}|
	foreach-object {
		$strFile=$_.FullName;
		$ObjBytes = $_.Length;
		$intBytesRemoved += $ObjBytes;	
		FileClean "$strFile";
	}
LogIt "Tomcat Cleanup complete."

# Summarize amount cleaned
$TotalMBytes=[Math]::Round($intBytesRemoved / 1048576,2);
$strTCleanMsg=$TotalMBytes.ToString() + " total megabytes removed."
LogIt $strTCleanMsg

# Rotate logs
LogIt "Rotating Logs ..."
rename-item -path "$strBbHome\logs\isapi_redirect.log" -newname "isapi_redirect-$dtStamp.log"
cmd /c "$strBbHome\tools\admin\RotateLogs.bat" |out-file $strCleanLog

# Move archived logs to backup location if specified
if ( $LogArchives -ne "") {
	LogIt "Moving Log Archives"
	if ( (test-path $LogArchives) -eq $true) {
		$strLogBuPath = "$LogArchives"
		get-childitem -path "$strBbHome\logs\archives\*" -include "*.zip" | 
		 foreach-object{
			move-item -path "$_" -destination "$strLogBuPath" | out-file $strCleanLog
		}
	}
	else {
		Logit "Unable to locate $LogArchives"
	}
}

# # Apply Microsoft Updates
# Create update objects
$UpdateSearcher = New-Object -ComObject Microsoft.Update.Searcher
$UpdateInstaller = New-Object -ComObject Microsoft.Update.Installer
$UpdateSession = New-Object -ComObject Microsoft.Update.Session

# Search for relevant updates.
# write-host "Searching for MS updates ..."
$UpdateCriteria = "IsInstalled=0 and Type='Software'"
$UpdateSearchResult = $UpdateSearcher.Search($UpdateCriteria).Updates

# Process updates if there are any
if ($UpdateSearchResult.Count -gt 0){
	$UpdateSearchResult |
	 foreach-object{
		$strUpdateId=$_.Identity;
		add-content -path "$strCleanLog" -value "Update $strUpdateId is available"
	}

	# Download updates.
	LogIt "Downloading MS updates ..."
	$UpdateDownloader = $UpdateSession.CreateUpdateDownloader()
	$UpdateDownloader.Updates = $UpdateSearchResult
	$UpdateDownloader.Download()

	# Install updates.
	LogIt "Installing MS updates ..."
	$UpdateInstaller.Updates = $UpdateSearchResult
	$UpdateResult = $UpdateInstaller.Install()
	if ($UpdateResult.rebootRequired -eq $true) {
	   $strNow = get-date -uformat %Y-%m-%d_%H%M
	   # Set exec service to manual to control services on bootup
	   set-service -name "BBLEARN-Exec" -StartupType Manual
	   LogIt "Rebooting server to apply windows updates at $strNow"
	   shutdown.exe /r /f /t 120 /d p:4:1
	   exit
	}
	else {
		LogIt "No reboot required for MS updates"
	}
}
else {
		LogIt "No MS updates available"
}
# eof