on run argv
	
	tell application "System Events"
		if not (exists process "iPhoto") then
			tell application "iPhoto"
				launch
				set visible of front window to true
			end tell
		end if
	end tell

	tell application "iPhoto"
		activate
		set photoPath to (item 1 of argv)
		set albumRSS to (item 2 of argv)
		if (album albumRSS exists) is not true then 
			new album name albumRSS
		end if
		import from (photoPath) to album albumRSS
	end tell
	
end run