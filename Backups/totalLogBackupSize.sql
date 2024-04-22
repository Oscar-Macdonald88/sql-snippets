SELECT TOP 100
    s.database_name,
    CAST(CAST(sum(s.backup_size) / 1000000 AS INT) AS VARCHAR(14)) + ' ' + 'MB' AS bkSize
FROM msdb.dbo.backupset s
    INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
WHERE
--s.database_name = '<DB Name>' And
Type = 'L' 
And backup_finish_date >= getdate() - 24
group by database_name
ORDER BY database_name
GO