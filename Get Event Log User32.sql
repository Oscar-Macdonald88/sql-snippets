-- Gets the most recent User32 event from the System event log
-- Requires xp_cmdshell to be enabled
exec xp_cmdshell 'wevtutil qe System /q:"*[System[Provider[@Name=''User32'']]]" /f:text /c:1 /rd:true'