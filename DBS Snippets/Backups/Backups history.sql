-- Get two weeks of Backup History
	SELECT
		s.database_name AS [Database],
		s.recovery_model AS [Model],
		'' AS [---],
		DATENAME(weekday, s.backup_start_date) AS [Day],
		CONVERT(VARCHAR(32), s.backup_start_date, 3) + ' - ' + CONVERT(VARCHAR(8), s.backup_start_date, 14) AS [Time],
		CASE s.type WHEN 'D' THEN 'Full' WHEN 'I' THEN 'Differential' WHEN 'L' THEN 'Transaction Log' END AS [bkType],
		CAST(CAST(s.backup_size/1048576 AS INT) AS VARCHAR(14)) + ' MB' AS [bkSize],
		m.physical_device_name AS [Device_Name]
	FROM msdb.dbo.backupset s
	INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
	WHERE 
		s.backup_start_date>=GETDATE()-14 -- ADJUST THE NUMBER OF DAYS YOU WANT
		AND s.database_name LIKE '%%' -- SELECT ONLY 1 DATABASE HERE IF YOU WANT
	ORDER BY s.backup_start_date DESC, s.database_name