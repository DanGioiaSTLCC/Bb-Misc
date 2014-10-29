#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=CollabLauncher.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; Vars
$sCollabFilePath=""
$sTimestamp=@YEAR&@MON&@MDAY&"_"&@HOUR&@MIN&@SEC ;Create Timestamp for renaming file


;Check for parameters used to call this scirpt
If $CmdLine[0] = 0 Then
	$iResultChooseFile = MsgBox(4, "No File Chosen", "No meeting file was specified. Do you want to select one?")
	;Open the file function when opted in
	If $iResultChooseFile =	6 Then
		Call(fnChooseFile)
	Else
		Exit
	EndIf
Else
	;identify opening paramter
	$sCollabFilePath=$CmdLine[1]
	Call(fnHandleMeeting)
EndIf

Func fnHandleMeeting()

	;Validate File Exists
	$iCollabFileExists = FileExists($sCollabFilePath)

	If $iCollabFileExists Then
		;move the file

		;Select Target Meeting File Path
		$sDestinationPath = "c:\temp\CollaborateMeetingFiles\meeting-" & $sTimestamp & ".jnlp"
		If $CmdLine[0] > 1 Then
			$sDestinationPath = $CmdLine[2];
		EndIf

		;Now Rename it
		FileMove($sCollabFilePath, $sDestinationPath, 8)

		;Execute the jnlp file to launch the meeting
		Call(fnLaunchMeetingJNLP, $sDestinationPath)
	Else
		$iResultChooseFile = MsgBox(4, "Invalid Path", "The meeting file specified does not exist. Do you want to select one?")
		If $iResultChooseFile =	6 Then
			Call(fnChooseFile)
		Else
			Exit
		EndIf
	EndIf
EndFunc

Func fnChooseFile()
	$sCollabFilePath = FileOpenDialog("Choose Meeting File","c:\","Collab (*.collab)|JNLP (*.jnlp)|All (*.*);",1)
	Call(fnHandleMeeting)
EndFunc

Func fnLaunchMeetingJNLP($sJnlpFilePath)
	ShellExecute($sJnlpFilePath)
EndFunc

;eof