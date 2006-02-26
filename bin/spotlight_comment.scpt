on run argv
   tell application "Finder"
     set comment of ((POSIX file (item 1 of argv)) as file) to (item 2 of argv)
     return
   end tell
end run
