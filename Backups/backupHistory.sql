SELECT TOP 100
    s.database_name,
    m.physical_device_name,
    s.user_name,
    CAST(s.backup_size / 1000000 AS INT) AS bkSizeMB,
    DATEDIFF(second, s.backup_start_date, s.backup_finish_date) AS TimeTakenSeconds,
    s.backup_start_date,
    CAST(s.first_lsn AS VARCHAR(50)) AS first_lsn,
    CAST(s.last_lsn AS VARCHAR(50)) AS last_lsn,
    CASE s.[type] WHEN 'D' THEN 'Full'
WHEN 'I' THEN 'Differential'
WHEN 'L' THEN 'Transaction Log'
END AS BackupType,
    s.server_name,
    s.recovery_model
FROM msdb.dbo.backupset s
    INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
WHERE 1=1
--AND s.database_name = '<DB Name>' 
--AND Type = 'D' 
And backup_finish_date >= GETDATE() -7
ORDER BY backup_start_date DESC, backup_finish_date
GO