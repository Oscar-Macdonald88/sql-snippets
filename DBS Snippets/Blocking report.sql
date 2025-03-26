DECLARE @sp_who2 TABLE (
	SPID INT,
	STATUS VARCHAR(MAX) --INT
	,
	LOGIN VARCHAR(MAX),
	HostName VARCHAR(MAX),
	BlkBy VARCHAR(MAX),
	DBName VARCHAR(MAX),
	Command VARCHAR(MAX),
	CPUTime INT,
	DiskIO VARCHAR(MAX),
	LastBatch VARCHAR(MAX),
	ProgramName VARCHAR(MAX),
	SPID_1 INT,
	REQUESTID INT
	)

INSERT INTO @sp_who2
EXEC sp_who2

UPDATE @sp_who2
SET ProgramName = CASE 
		WHEN (ProgramName LIKE '%Job 0x%')
			THEN 'SQLAgent - Agent Job: "' + (
					SELECT TOP 1 name
					FROM msdb.dbo.sysjobs
					WHERE ProgramName LIKE '%' + master.dbo.fn_varbintohexstr(job_id) + '%'
					) + '"'
		ELSE ProgramName
		END;

SELECT sp.SPID,
	sp.STATUS,
	sp.[LOGIN],
	sp.HostName,
	sp.BlkBy,
	sp.DBName,
	sp.Command,
	sp.ProgramName,
	der.start_time,
	sp.LastBatch,
	der.TEXT,
	'' AS [---],
	'KILL ' + CONVERT(VARCHAR(32), sp.SPID) + ' WITH STATUSONLY' AS [T-SQL]
FROM @sp_who2 sp
LEFT JOIN (
	SELECT der.session_id,
		der.start_time,
		der.STATUS,
		der.command,
		dest.TEXT
	FROM master.sys.dm_exec_requests der
	CROSS APPLY master.sys.dm_exec_sql_text(der.sql_handle) dest
	WHERE der.session_id IN (
			SELECT SPID
			FROM @sp_who2
			WHERE BlkBy NOT LIKE '%.%'
				OR SPID IN (
					SELECT BlkBy
					FROM @sp_who2
					WHERE BlkBy NOT LIKE '%.%'
					)
			)
	) der ON (sp.SPID = der.session_id)
WHERE sp.BlkBy NOT LIKE '%.%'
	OR sp.SPID IN (
		SELECT BlkBy
		FROM @sp_who2
		WHERE BlkBy NOT LIKE '%.%'
		)
ORDER BY sp.BlkBy
