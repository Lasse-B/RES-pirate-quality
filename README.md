# RES-pirate-quality
Parses Elite Dangerous log files and tells you the quality of pirate spawns in RES.
At startup you can choose / confirm a hotkey with which you then can mute / unmute voice output.
In case you forget to do it yourself (like after a game update), it will automatically set VerboseLogging to 1 and remind you to restart Elite Dangerous.


You can of course enable verbose logging manually in Elite Dangerous. To do so:
- find the file named 'AppConfig.xml' located in your 'Elite Dangerous\Products\FORC-FDEV-D-XXXX' folder
- open it using Windows Notepad
- scroll down to the '<Network' section
- insert 'VerboseLogging="1"' right after '<Network' so it looks like this:
```
	<Network
	  VerboseLogging="1"
```
- save the file and (re)start Elite Dangerous
