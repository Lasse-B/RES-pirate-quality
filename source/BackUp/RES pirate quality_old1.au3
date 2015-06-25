#include <array.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <HotKeyInput.au3>
#include <HotKey_21b.au3>

Opt("TrayAutoPause", 0)

Global $PIDfound = 0, $PIDlocation = "", $ExeLocation = "", $LogLocation = "", $LogFile = "", $aStatus[1][2] = [["0", "0"]], $Form, $HKI1, $HKI2, $Button, $Text, $running = 1

global $title = 'RES pirate quality v1.2'

_KeyLock(0x062E) ; we do want Ctrl+Alt+Del to be locked away from this script ;)
$Form = GUICreate($title, 300, 160)
$HKI1 = _GUICtrlHKI_Create(0, 56, 75, 230, 20)
$hk = IniRead(@ScriptDir & "\config.ini", "options", "hotkey", 0)
If StringLen($hk) = 6 And StringRegExp($hk, "0x[0-9A-F]{4}", 0) Then _GUICtrlHKI_SetHotKey($HKI1, $hk)

GUICtrlCreateLabel('Hotkey:', 10, 78, 44, 14)
GUICtrlCreateLabel('Click on Input box and hold a combination of keys.' & @CR & 'Press OK to save the hotkey and proceed.' & @CR & 'This hotkey can then be used to mute / unmute voice output', 10, 10, 280, 53)
$Button = GUICtrlCreateButton('OK', 110, 124, 80, 23)
GUICtrlSetState(-1, BitOR($GUI_DEFBUTTON, $GUI_FOCUS))
GUISetState()

While 1
	Switch GUIGetMsg()
		Case $GUI_EVENT_CLOSE
			Exit
		Case $Button
			$hk = '0x' & StringRight(Hex(_GUICtrlHKI_GetHotKey($HKI1)), 4)
			$test = IniWrite(@ScriptDir & "\config.ini", "options", "hotkey", $hk)
			_HotKey_Assign($hk, "_toggle", $HK_FLAG_NOREPEAT)
			GUIDelete($Form)
			ExitLoop
	EndSwitch
WEnd

While 1
	Sleep(500)
	; find out where EliteDangerous32.exe is running from, get its path, add "Logs" and we got the logs directory
	If $PIDfound = 0 And ProcessExists("elitedangerous32.exe") Then
		$aProcessList = ProcessList("elitedangerous32.exe")
		If $aProcessList[0][0] > 1 Then ; running multiple instances of E:D is bad since we can't provide reliable info if there are multiple scenarios running
			MsgBox(16, $title, "Error" & @crlf & @crlf & "Elite Dangerous has multiple instances running. Cannot continue.")
			Exit
		EndIf
		$PIDfound = $aProcessList[1][1]
		$PIDlocation = _ProcessGetLocation($PIDfound)
		$pathsplit = StringSplit($PIDlocation, "\")
		For $i = 1 To $pathsplit[0] - 1
			$ExeLocation &= $pathsplit[$i] & "\"
		Next
		$LogLocation = $ExeLocation & "Logs"
		if not fileexists($LogLocation) Then ; just in case the Logs dir is not there for some reason
			msgbox(16, $title, "Error" & @crlf & @crlf & "Logs path not found, cannot continue.")
			Exit
		EndIf
		if not fileexists($ExeLocation & "AppConfig.xml") Then
			msgbox(64, $title, "Note" & @crlf & @crlf & "AppConfig.xml not found, please make sure you enabled verbose logging in Elite Dangerous manually.")
		Else
			_verboseLogging()
		EndIf
	EndIf
	If $PIDfound <> 0 And Not ProcessExists("elitedangerous32.exe") Then ; need to reset all the variables between gaming sessions, otherwise we end up with outdated or no info
		$PIDfound = 0
		$PIDlocation = ""
		$LogLocation = ""
		$ExeLocation = ""
		$LogFile = ""
		Dim $aStatus[1][2] = [["0", "0"]]
	EndIf

	If $PIDfound <> 0 Then $LogFile = _MostRecentNetLog() ; log file might change when disconnecting / reconnecting, so we need to always make sure we get the most current one

	If Not ($LogFile = "") Then _checkLog()
WEnd

Func _verboseLogging()
	$aContent = FileReadToArray($ExeLocation & "AppConfig.xml")
	$iStart = _ArraySearch($aContent, "<network", 0, 0, 0, 1)
	$iEnd = _ArraySearch($aContent, "</network>", $iStart, 0, 0, 1)

	For $i = $iStart To $iEnd
		If StringInStr($aContent[$i], "verboselogging") Then
			$return = StringRegExp($aContent[$i], '".*(\d).*"', 1)
			If IsArray($return) Then
				If $return[0] = 1 Then
					;_FileWriteFromArray($ExeLocation & "AppConfig.xml", $aContent)
					Return 1
				else
					$aContent[$i] = StringRegExpReplace($aContent[$i], '".*(\d).*"', '"1"')
					_FileWriteFromArray($ExeLocation & "AppConfig.xml", $aContent)
					msgbox(64, $title, "Note" & @crlf & @crlf & "Verbose logging was enabled in AppConfig.xml. Please remember to restart Elite Dangerous.")
					Return 0
				EndIf

			EndIf
		EndIf
		If $i = $iEnd Then
			_ArrayInsert($aContent, $iStart + 1, @TAB & '  VerboseLogging="1"')
			_FileWriteFromArray($ExeLocation & "AppConfig.xml", $aContent)
			msgbox(64, $title, "Note" & @crlf & @crlf & "Verbose logging was enabled in AppConfig.xml. Please remember to restart Elite Dangerous.")
			Return 2
		EndIf
	Next
	Return -1
EndFunc   ;==>_verboseLogging

Func _toggle()
	$running *= -1
	If $running = -1 Then _TalkOBJ("mute")
	If $running = 1 Then _TalkOBJ("unmute")
EndFunc   ;==>_toggle

Func _checkLog()
	$aSettings = IniReadSection(@ScriptDir & "\config.ini", "settings"); [$i][0] holds the item to search for (= key), [$i][1] holds the text to say when that item was found (= value)
	If Not IsArray($aSettings) Then Return 0
	$LogContent = FileRead($LogFile)

	; loop through the keys in config.ini
	For $i = 1 To $aSettings[0][0]
		$status = StringRegExp($LogContent, "(?im).*?" & $aSettings[$i][0] & ".*?", 3) ; look for lines in the log that have this key

		If Not IsArray($status) Then ContinueLoop ; skip the rest of this loop if no line had that key

		$sTime = StringRegExp($status[UBound($status) - 1], "\{(.*?)\}", 1)[0] ; extract the time from the last line of the log that contained the key

		$index = _ArraySearch($aStatus, $aSettings[$i][0], 0, 0, 0, 0, 1, 0) ; check our status "table" if we already have an entry for this particular key or not
		If $index < 0 Then ; if key is not yet present, extend the status table by one row and add both the key as well as the time it last appeared in the log
			ReDim $aStatus[UBound($aStatus) + 1][2]
			$aStatus[UBound($aStatus) - 1][0] = $aSettings[$i][0]
			$aStatus[UBound($aStatus) - 1][1] = $sTime
			If $running = 1 Then _TalkOBJ($aSettings[$i][1]) ; notify player
		Else ; just update the time if we already have an entry for the key
			If $aStatus[$index][1] <> $sTime Then
				$aStatus[$index][1] = $sTime
				If $running = 1 Then _TalkOBJ($aSettings[$i][1]) ; notify player
			EndIf
		EndIf
	Next

	; as players add, change or remove keys in config.ini, the status table may hold obsolete lines which should be cleaned up
	For $i = (UBound($aStatus) - 1) To 1 Step -1
		If _ArraySearch($aSettings, $aStatus[$i][0], 1, 0, 0, 0, 1, 0) < 0 Then _ArrayDelete($aStatus, $i)
	Next
EndFunc   ;==>_checkLog

Func _MostRecentNetLog()
	If $LogLocation = "" Then Return 0

	$aLogList = _FileListToArray($LogLocation, "netlog*.log", 1, 1)
	_ArraySort($aLogList, 1, 1)
	Return $aLogList[1]
EndFunc   ;==>_MostRecentNetLog

Func _ProcessGetLocation($iPID)
	Local $aProc = DllCall('kernel32.dll', 'hwnd', 'OpenProcess', 'int', BitOR(0x0400, 0x0010), 'int', 0, 'int', $iPID)
	If $aProc[0] = 0 Then Return SetError(1, 0, '')
	Local $vStruct = DllStructCreate('int[1024]')
	DllCall('psapi.dll', 'int', 'EnumProcessModules', 'hwnd', $aProc[0], 'ptr', DllStructGetPtr($vStruct), 'int', DllStructGetSize($vStruct), 'int_ptr', 0)
	Local $aReturn = DllCall('psapi.dll', 'int', 'GetModuleFileNameEx', 'hwnd', $aProc[0], 'int', DllStructGetData($vStruct, 1), 'str', '', 'int', 2048)
	If StringLen($aReturn[3]) = 0 Then Return SetError(2, 0, '')
	Return $aReturn[3]
EndFunc   ;==>_ProcessGetLocation

Func _TalkOBJ($s_text)
	Local $o_speech = ObjCreate("SAPI.SpVoice")
	$o_speech.Speak($s_text)
	$o_speech = ""
EndFunc   ;==>_TalkOBJ
