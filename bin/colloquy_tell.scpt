on run argv
	
	tell application "System Events"
		if not (exists process "Colloquy") then
			tell application "Colloquy"
				launch
				set visible of front window to true
			end tell
		end if
	end tell
	
	tell application "Colloquy"
		send message (item 1 of argv) action tense yes to (get chat room (item 3 of argv) of first connection)
		send message (item 2 of argv) action tense yes to (get chat room (item 3 of argv) of first connection)
		return
	end tell
	
end run