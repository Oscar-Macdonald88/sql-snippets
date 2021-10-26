--Show the Percent Complete and Time Remaining for a running job
	SELECT 
		session_id, 
		DB_NAME(database_id) AS [database], 
		command, 
		percent_complete, 
		'' AS [--Remaining-->],
		RIGHT('0000'+CONVERT(VARCHAR(6),((estimated_completion_Time/1000)/86400)),4) AS [days], 
		RIGHT('00'+CONVERT(VARCHAR(3),(((estimated_completion_Time/1000)%86400)/3600)),2) AS [hours],
		RIGHT('00'+CONVERT(VARCHAR(3),((((estimated_completion_Time/1000)%86400)%3600)/60)),2) AS [minutes],
		RIGHT('00'+CONVERT(VARCHAR(3),((((estimated_completion_Time/1000)%86400)%3600)%60)),2) AS [seconds]
	FROM sys.dm_exec_requests 
	WHERE percent_complete>0