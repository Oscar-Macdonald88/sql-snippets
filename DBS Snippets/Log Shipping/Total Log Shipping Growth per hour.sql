-- Alex's Log Shipping "Total T-Log Size" Report
	WITH TLogBackups AS (
		SELECT TOP 10000
			SERVERPROPERTY('ServerName') AS [Server],
			s.database_name,
			backup_start_date,
			CONVERT(VARCHAR(32), s.backup_start_date, 3) + ' - ' + CONVERT(VARCHAR(8), s.backup_start_date, 14) AS [Backup_Time],
			CONVERT(DATE, s.backup_start_date) AS [Date],
			DATEPART(HOUR, s.backup_start_date) AS [Hour],
			backup_size
		FROM msdb.dbo.backupset s
		INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
		LEFT JOIN msdb.dbo.restorehistory h ON (h.backup_set_id=s.backup_set_id)
		WHERE s.type IN ('L')
			AND backup_start_date > DATEADD(DAY, -1, GETDATE())
		ORDER BY backup_start_date DESC
	)
	SELECT 
		Server,
		Date,
		CONVERT(VARCHAR(10), Hour)+':00:00 - '+CONVERT(VARCHAR(10), Hour)+':59:59' AS [Time],
		COUNT(database_name) AS [Databases],
		CASE	
			WHEN (SUM(backup_size)<1048576) THEN CAST(CAST(SUM(backup_size)/1024 AS INT) AS VARCHAR(14)) + ' KB' 
			WHEN (SUM(backup_size)>=1048576) THEN CAST(CAST(SUM(backup_size)/1048576 AS INT) AS VARCHAR(14)) + ' MB' 
		END AS [Total_TLog_Size] 
	FROM TLogBackups
	GROUP BY Server, Date, Hour	
	ORDER BY Date DESC, Hour DESC