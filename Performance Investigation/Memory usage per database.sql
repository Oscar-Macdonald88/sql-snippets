SELECT DB_NAME(database_id) AS DatabaseName,
COUNT (1) * 8 / 1024 AS MBUsed
FROM sys.dm_os_buffer_descriptors
WHERE DB_NAME(database_id) IS NOT NULL
--and database_id > 4
--and DB_NAME(database_id) <> 'EIT_DBA'
GROUP BY database_id
ORDER BY COUNT (*) * 8 / 1024 DESC
GO