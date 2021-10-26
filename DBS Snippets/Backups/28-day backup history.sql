-- Get the last 28-days worth of daily Backup History
	WITH BackupReport AS (
		SELECT
			s.database_name AS [Database],
			DATENAME(weekday, s.backup_start_date) AS [Day],
			s.type
		FROM msdb.dbo.backupset s
		INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
		WHERE 
			s.backup_start_date >= GETDATE()-28 --CHANGE THIS!
			AND s.type IN ('D', 'I', 'L')
	), BackupReportFull AS (
		SELECT 
			[Database] AS [name],
			SUM(CASE WHEN (Day='Monday') THEN 1 ELSE 0 END) AS [F_Mon],
			SUM(CASE WHEN (Day='Tuesday') THEN 1 ELSE 0 END) AS [F_Tue],
			SUM(CASE WHEN (Day='Wednesday') THEN 1 ELSE 0 END) AS [F_Wed],
			SUM(CASE WHEN (Day='Thursday') THEN 1 ELSE 0 END) AS [F_Thu],
			SUM(CASE WHEN (Day='Friday') THEN 1 ELSE 0 END) AS [F_Fri],
			SUM(CASE WHEN (Day='Saturday') THEN 1 ELSE 0 END) AS [F_Sat],
			SUM(CASE WHEN (Day='Sunday') THEN 1 ELSE 0 END) AS [F_Sun]
		FROM BackupReport 
		WHERE (type = 'D')
		GROUP BY [Database]
	), BackupReportDiff AS (
		SELECT 
			[Database] AS [name],
			SUM(CASE WHEN (Day='Monday') THEN 1 ELSE 0 END) AS [D_Mon],
			SUM(CASE WHEN (Day='Tuesday') THEN 1 ELSE 0 END) AS [D_Tue],
			SUM(CASE WHEN (Day='Wednesday') THEN 1 ELSE 0 END) AS [D_Wed],
			SUM(CASE WHEN (Day='Thursday') THEN 1 ELSE 0 END) AS [D_Thu],
			SUM(CASE WHEN (Day='Friday') THEN 1 ELSE 0 END) AS [D_Fri],
			SUM(CASE WHEN (Day='Saturday') THEN 1 ELSE 0 END) AS [D_Sat],
			SUM(CASE WHEN (Day='Sunday') THEN 1 ELSE 0 END) AS [D_Sun]
		FROM BackupReport
		WHERE (type = 'I')
		GROUP BY [Database]
	), BackupReportTLog AS (
		SELECT 
			[Database] AS [name],
			SUM(CASE WHEN (Day='Monday') THEN 1 ELSE 0 END) AS [L_Mon],
			SUM(CASE WHEN (Day='Tuesday') THEN 1 ELSE 0 END) AS [L_Tue],
			SUM(CASE WHEN (Day='Wednesday') THEN 1 ELSE 0 END) AS [L_Wed],
			SUM(CASE WHEN (Day='Thursday') THEN 1 ELSE 0 END) AS [L_Thu],
			SUM(CASE WHEN (Day='Friday') THEN 1 ELSE 0 END) AS [L_Fri],
			SUM(CASE WHEN (Day='Saturday') THEN 1 ELSE 0 END) AS [L_Sat],
			SUM(CASE WHEN (Day='Sunday') THEN 1 ELSE 0 END) AS [L_Sun]
		FROM BackupReport
		WHERE (type = 'L')
		GROUP BY [Database]
	)
	SELECT 
		SERVERPROPERTY('ServerName') AS [Server],
		db.name AS [Database], '' AS [-],
		brf.F_Mon, brf.F_Tue, brf.F_Wed, brf.F_Thu, brf.F_Fri, brf.F_Sat, brf.F_Sun, '' AS [-],
		brd.D_Mon, brd.D_Tue, brd.D_Wed, brd.D_Thu, brd.D_Fri, brd.D_Sat, brd.D_Sun, '' AS [-],
		brl.L_Mon, brl.L_Tue, brl.L_Wed, brl.L_Thu, brl.L_Fri, brl.L_Sat, brl.L_Sun
	FROM msdb.sys.sysdatabases db
	LEFT JOIN BackupReportFull brf ON (brf.name = db.name)
	LEFT JOIN BackupReportDiff brd ON (brd.name = db.name)
	LEFT JOIN BackupReportTLog brl ON (brl.name = db.name)
	ORDER BY db.name