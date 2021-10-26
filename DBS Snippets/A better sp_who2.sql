-- Filter the output of sp_who2.
	DECLARE @sp_who2 TABLE(SPID INT, Status VARCHAR(MAX), LOGIN VARCHAR(MAX), HostName VARCHAR(MAX), BlkBy VARCHAR(MAX), DBName VARCHAR(MAX), Command VARCHAR(MAX), CPUTime INT, DiskIO INT, LastBatch VARCHAR(MAX), ProgramName VARCHAR(MAX), SPID_1 INT, REQUESTID INT)
	INSERT INTO @sp_who2 EXEC sp_who2
	update @sp_who2 set ProgramName = case when (ProgramName like '%Job 0x%') then 'SQLAgent - Agent Job: "' + (select top 1 name FROM msdb.dbo.sysjobs where ProgramName like '%'+master.dbo.fn_varbintohexstr(job_id)+'%') + '"' else ProgramName end;
 	SELECT 
		*, '' AS [----],
		'KILL '+CONVERT(VARCHAR(25), SPID) AS [Kill_T-SQL], 
		'DBCC INPUTBUFFER ('+CONVERT(VARCHAR(25), SPID)+')' AS [Command_T-SQL],
		'xp_logininfo '''+LOGIN+'''' AS [Login_T-SQL]
	FROM @sp_who2
	WHERE 1=1 /* UNCOMMENT AND USE ANY OF THE BELOW FILTERS */
		--AND [Status] LIKE '%%'
		--AND [Login] LIKE '%%'
		--AND HostName LIKE '%%'
		--AND BlkBy NOT LIKE '%.%' OR SPID IN (SELECT CONVERT(INT,REPLACE(REPLACE(BlkBy,' ',''),'.','')) FROM @sp_who2)
		--AND DBName LIKE '%%'
		--AND Command LIKE '%%'
		--AND CPUTime >= 0
		--AND DiskIO >= 0
		--AND ProgramName LIKE '%%'