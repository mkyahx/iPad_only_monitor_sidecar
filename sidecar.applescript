-- Open Displays settings and try to connect an iPad via Sidecar.
-- Usage:
--   osascript sidecar.applescript
--   osascript sidecar.applescript "Steven's iPad"

use framework "Foundation"

property targetDevice : "iPad"

on run argv
	if (count of argv) > 0 then set targetDevice to item 1 of argv
	
	tell application "System Settings"
		activate
	end tell
	my openDisplaysSettings()
	
	delay 2
	
	tell application "System Events"
		if not (exists process "System Settings") then error "System Settings is not running."
		
		tell process "System Settings"
			set frontmost to true
			my waitForWindow("System Settings", 10)
			my waitForDisplaysControls(30)
			
			if my isDeviceConnected(targetDevice) then
				return targetDevice & " is already connected."
			end if
			
			my connectSidecarDevice(targetDevice)
			delay 5
			
			if my isDeviceConnected(targetDevice) then
				return "Connected " & targetDevice & " successfully."
			end if
			
			error "Selected " & targetDevice & ", but it did not appear as a connected display."
		end tell
	end tell
end run

on openDisplaysSettings()
	set settingsURL to current application's NSURL's URLWithString:"x-apple.systempreferences:com.apple.Displays-Settings.extension"
	set openedSettings to current application's NSWorkspace's sharedWorkspace()'s openURL:settingsURL
	if openedSettings as boolean is false then error "Could not open Displays settings URL."
end openDisplaysSettings

on waitForWindow(processName, timeoutSeconds)
	tell application "System Events"
		repeat with i from 1 to timeoutSeconds * 2
			try
				if exists window 1 of process processName then return true
			end try
			delay 0.5
		end repeat
	end tell
	error "Timed out waiting for " & processName & " window."
end waitForWindow

on waitForDisplaysControls(timeoutSeconds)
	tell application "System Events"
		repeat with i from 1 to timeoutSeconds * 2
			try
				tell process "System Settings"
					if exists menu button 1 of group 1 of group 3 of splitter group 1 of group 1 of window 1 then return true
				end tell
			end try
			delay 0.5
		end repeat
	end tell
	error "Timed out waiting for Displays controls."
end waitForDisplaysControls

on isDeviceConnected(deviceName)
	tell application "System Events"
		try
			tell process "System Settings"
				set displayButtons to buttons of scroll area 1 of group 1 of group 3 of splitter group 1 of group 1 of window 1
				if (count of displayButtons) > 2 then return true
				repeat with displayButton in displayButtons
					if my textForElement(displayButton) contains deviceName then return true
				end repeat
				
				set displayOptions to pop up buttons of group 1 of scroll area 2 of group 1 of group 3 of splitter group 1 of group 1 of window 1
				repeat with displayOption in displayOptions
					if my textForElement(displayOption) contains deviceName then return true
				end repeat
			end tell
		end try
	end tell
	return false
end isDeviceConnected

on connectSidecarDevice(deviceName)
	tell application "System Events"
		tell process "System Settings"
			set addButton to menu button 1 of group 1 of group 3 of splitter group 1 of group 1 of window 1
			click addButton
			delay 1
			
			try
				set sidecarItem to my sidecarMenuItem(menu 1 of addButton, deviceName)
				click sidecarItem
			on error menuError
				key code 53
				error menuError
			end try
		end tell
	end tell
end connectSidecarDevice

on sidecarMenuItem(addMenu, deviceName)
	tell application "System Events"
		set candidateItems to {}
		set afterMirrorSection to false
		
		repeat with menuItem in menu items of addMenu
			set itemText to my textForElement(menuItem)
			
			if itemText contains "airplayvideo" then return menuItem
			
			if itemText contains "镜像或扩展至" or itemText contains "Mirror or extend to" then
				set afterMirrorSection to true
			else if afterMirrorSection and itemText contains deviceName then
				return menuItem
			else if itemText contains deviceName then
				set end of candidateItems to menuItem
			end if
		end repeat
		
		if (count of candidateItems) > 0 then return item -1 of candidateItems
	end tell
	
	error "No Sidecar menu item matching '" & deviceName & "'."
end sidecarMenuItem

on textForElement(uiElement)
	set parts to {}
	tell application "System Events"
		try
			set end of parts to name of uiElement as text
		end try
		try
			set end of parts to description of uiElement as text
		end try
		try
			set end of parts to title of uiElement as text
		end try
		try
			set end of parts to value of uiElement as text
		end try
		try
			set attributeNames to name of attributes of uiElement
			if attributeNames contains "AXIdentifier" then
				set end of parts to value of attribute "AXIdentifier" of uiElement as text
			end if
		end try
	end tell
	return parts as text
end textForElement
