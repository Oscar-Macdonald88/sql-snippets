SELECT name, SUSER_SNAME(owner_sid) AS [Owner], 
		'EXEC msdb.dbo.sp_update_job @job_id=N'''+CONVERT(VARCHAR(128),job_id)+''', @owner_login_name=N''sa''' AS [T-SQL_ChangeToSA]
	FROM msdb.dbo.sysjobs 
	WHERE SUSER_SNAME(owner_sid) <> 'sa'