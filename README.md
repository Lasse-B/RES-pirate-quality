# RES-pirate-quality
parses Elite Dangerous log files and tells you the quality of pirate spawns in RES

Just remember to enable verbose logging in Elite Dangerous. To do so:
- find the file named 'AppConfig.xml' located in your 'Elite Dangerous\Products\FORC-FDEV-D-XXXX' folder
- open it using Windows Notepad
- scroll down to the '<Network' section
- insert 'VerboseLogging="1"' right after '<Network' so it looks like this:
```
	<Network
	  VerboseLogging="1"
```
- save the file and (re)start Elite Dangerous
