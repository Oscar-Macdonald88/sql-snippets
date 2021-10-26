--Check Version Store usage first. See Q:\DBA Team\Version_Store\VersionStore.docx for more details if it's using heaps of space
	execute ('use [tempdb]; select (sum(version_store_reserved_page_count)*8)/1024  as ''VersionStore_MB'' from sys.dm_db_file_space_usage;');
 
--Who's blowing out TempDB
	WITH task_alloc AS (
		SELECT
			CONVERT(VARCHAR(10), session_id) AS [SPID], 
			DB_NAME(database_id) AS [Database],
			request_id,
			CAST((SUM(internal_objects_alloc_page_count + user_objects_alloc_page_count) * 8.0/1024.0) AS NUMERIC(10,1)) AS [task_alloc_pages_MB],
			CAST((SUM(internal_objects_dealloc_page_count + user_objects_dealloc_page_count) * 8.0/1024.0) AS NUMERIC(10,1)) AS [task_dealloc_pages_MB]
		FROM sys.dm_db_task_space_usage
		GROUP BY session_id, database_id, request_id
	)
	SELECT *, '' AS [-], 'EXEC sp_who2 '+SPID+';' AS [sp_who2], 'DBCC INPUTBUFFER('+SPID+');' AS [Buffer] --,CASE WHEN (SPID>50) THEN 'KILL '+SPID+';' ELSE '' END AS [Kill]
	FROM task_alloc 
	WHERE [Database] = 'tempdb' --AND task_alloc_pages_MB > 0
	ORDER BY task_alloc_pages_MB DESC
 
--Who's blowing out TempDB (alt, sometimes works)
	SELECT database_transaction_log_bytes_reserved,session_id 
	FROM sys.dm_tran_database_transactions AS tdt 
	INNER JOIN sys.dm_tran_session_transactions AS tst 
	ON tdt.transaction_id = tst.transaction_id 
	WHERE database_id = 2;