--Show backup history for a single database, showing recovery path
	DECLARE @database VARCHAR(255), @last_full_finish DATETIME
	SET @database = '' -- ENTER DATABASE NAME HERE
 
	SELECT TOP 1 @last_full_finish=backup_finish_date 
	FROM msdb.dbo.backupset 
	WHERE type='D' AND database_name=@database 
	ORDER BY backup_start_date DESC
 
	SELECT	s.database_name AS [Database],
		CONVERT(VARCHAR(32), s.backup_start_date, 3) + ' - ' + CONVERT(VARCHAR(8), s.backup_start_date, 14) AS [Start_time],
		CONVERT(VARCHAR(32), s.backup_finish_date, 3) + ' - ' + CONVERT(VARCHAR(8), s.backup_finish_date, 14) AS [End_time],
		CASE s.type WHEN 'D' THEN 'Full' WHEN 'I' THEN 'Differential' WHEN 'L' THEN 'Transaction Log' END AS [Backup_type],
		CAST(CAST(s.backup_size/1048576 AS INT) AS VARCHAR(14)) + ' MB' AS [Size],
		m.physical_device_name AS [Filename]
	FROM msdb.dbo.backupset s
	INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
	WHERE s.database_name=@database AND (s.backup_start_date>=@last_full_finish OR (s.backup_finish_date=@last_full_finish AND s.type='D'))
	ORDER BY s.backup_start_date DESC, s.database_name