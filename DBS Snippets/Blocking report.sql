-- Blocking tool
	DECLARE @sp_who2 
	TABLE(
		SPID INT
		, Status VARCHAR(MAX) --INT
		, LOGIN VARCHAR(MAX)
		, HostName VARCHAR(MAX)
		, BlkBy VARCHAR(MAX)
		, DBName VARCHAR(MAX)
		, Command VARCHAR(MAX)
		, CPUTime INT
		, DiskIO VARCHAR(MAX)
		, LastBatch VARCHAR(MAX)
		, ProgramName VARCHAR(MAX)
		, SPID_1 INT,
		 REQUESTID INT)
	INSERT INTO @sp_who2 EXEC sp_who2
 
	update @sp_who2 set ProgramName = case when (ProgramName like '%Job 0x%') then 'SQLAgent - Agent Job: "' + (select top 1 name FROM msdb.dbo.sysjobs where ProgramName like '%'+master.dbo.fn_varbintohexstr(job_id)+'%') + '"' else ProgramName end;
 
	SELECT sp.SPID, sp.Status, sp.[LOGIN], sp.HostName, sp.BlkBy, sp.DBName, sp.Command, sp.ProgramName, der.start_time, sp.LastBatch, der.text, '' AS [---], 'KILL '+CONVERT(VARCHAR(32),sp.SPID) AS [T-SQL]
	FROM @sp_who2 sp
	LEFT JOIN (
		SELECT der.session_id, der.start_time, der.status, der.command, dest.text 
		FROM master.sys.dm_exec_requests der 
		CROSS APPLY master.sys.dm_exec_sql_text(der.sql_handle) dest 
		WHERE der.session_id IN (
			SELECT SPID FROM @sp_who2
			WHERE BlkBy NOT LIKE '%.%' 
				OR SPID IN (SELECT BlkBy FROM @sp_who2 WHERE BlkBy NOT LIKE '%.%')
		)
	) der ON (sp.SPID=der.session_id)
	WHERE sp.BlkBy NOT LIKE '%.%' 
		OR sp.SPID IN (SELECT BlkBy FROM @sp_who2 WHERE BlkBy NOT LIKE '%.%')
	ORDER BY sp.BlkBy