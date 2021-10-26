-- Alex's Log Shipping "Problem DB" Report - run on both the Primary AND the Secondary server (2005 - 2008 / R2 version)
	DECLARE @problemDB NVARCHAR(255);
	SET @problemDB = ''; -- ENTER THE PROBLEM DB NAME
 
	SELECT TOP 100
		CASE WHEN @problemDB IN (SELECT primary_database FROM msdb.dbo.log_shipping_primary_databases) THEN '[Primary]' ELSE '' END 
		+ CASE WHEN @problemDB IN (SELECT secondary_database FROM msdb.dbo.log_shipping_secondary_databases) THEN '[Secondary]' ELSE '' END AS [State],
		SERVERPROPERTY('ServerName') AS [Server],
		RIGHT(m.physical_device_name, coalesce(CHARINDEX('\', REVERSE(m.physical_device_name)), len(m.physical_device_name))-1) AS [File],
		RIGHT(m.physical_device_name, COALESCE(NULLIF(CHARINDEX('\',REVERSE(m.physical_device_name))-1, -1), LEN(m.physical_device_name))) AS [File],
		CONVERT(VARCHAR(32), s.backup_start_date, 3) + ' - ' + CONVERT(VARCHAR(8), s.backup_start_date, 14) AS [Backup_Time],
		CONVERT(VARCHAR(32), h.restore_date, 3) + ' - ' + CONVERT(VARCHAR(8), h.restore_date, 14) AS [Restore_Time],
		DATEDIFF(mi, s.backup_start_date, h.restore_date) AS [Latency],
		CAST(CAST(s.backup_size / 1048576.00 AS NUMERIC(36,2)) AS VARCHAR(32)) + ' MB' AS [TLog_Size],
		m.physical_device_name AS [TLog_Filename]
	FROM msdb.dbo.backupset s
	INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
	LEFT JOIN msdb.dbo.restorehistory h ON (h.backup_set_id=s.backup_set_id)
	WHERE s.type IN ('L') AND s.database_name=@problemDB
	ORDER BY s.backup_start_date DESC, h.restore_date DESC, s.database_name;

-- Alex's Second Log Shipping "Problem DB" Report - run on both the Primary AND the Secondary server
DECLARE @problemDB NVARCHAR(255);
SET @problemDB = ''; -- ENTER THE PROBLEM DB NAME

SELECT TOP 100
    CASE WHEN @problemDB IN (SELECT primary_database FROM msdb.dbo.log_shipping_primary_databases) THEN '[Primary]' ELSE '' END 
    + CASE WHEN @problemDB IN (SELECT secondary_database FROM msdb.dbo.log_shipping_secondary_databases) THEN '[Secondary]' ELSE '' END AS [State],
    SERVERPROPERTY('ServerName') AS [Server],
    RIGHT(m.physical_device_name, coalesce(CHARINDEX('\', REVERSE(m.physical_device_name)), len(m.physical_device_name))-1) AS [File],
    RIGHT(m.physical_device_name, COALESCE(NULLIF(CHARINDEX('\',REVERSE(m.physical_device_name))-1, -1), LEN(m.physical_device_name))) AS [File],
    CONVERT(VARCHAR(32), s.backup_start_date, 3) + ' - ' + CONVERT(VARCHAR(8), s.backup_start_date, 14) AS [Backup_Time],
    CONVERT(VARCHAR(32), h.restore_date, 3) + ' - ' + CONVERT(VARCHAR(8), h.restore_date, 14) AS [Restore_Time],
    DATEDIFF(mi, s.backup_start_date, h.restore_date) AS [Latency],
    CAST(CAST(s.backup_size / 1048576.00 AS NUMERIC(36,2)) AS VARCHAR(32)) + ' MB' AS [TLog_Size],
    m.physical_device_name AS [TLog_Filename],
    -- /*
    '' as [-],
    case 
        when (coalesce(LAG(s.first_lsn,1) OVER (ORDER BY s.backup_start_date DESC), s.last_lsn) = s.last_lsn) then 'OK'
        else 'Check'
    end as [LSN_Check],
    case 
        when (coalesce(LAG(s.first_recovery_fork_guid,1) OVER (ORDER BY s.backup_start_date DESC), s.last_recovery_fork_guid) = s.last_recovery_fork_guid) then 'OK'
        else 'Check'
    end as [FORK_Check]
    -- */
    -- , s.first_lsn, s.last_lsn, s.first_recovery_fork_guid, s.last_recovery_fork_guid
FROM msdb.dbo.backupset s
INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
LEFT JOIN msdb.dbo.restorehistory h ON (h.backup_set_id=s.backup_set_id)
WHERE /* s.type IN ('D', 'L') AND */ s.database_name=@problemDB
ORDER BY s.backup_start_date DESC, h.restore_date DESC, s.database_name;