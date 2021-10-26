-- get the current running backups and how long they will take

SELECT session_id as SPID, command, start_time, percent_complete, dateadd(second,estimated_completion_time/1000, getdate()) as estimated_completion_time, a.text AS Query
FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a 
WHERE r.command in ('BACKUP DATABASE','RESTORE DATABASE', 'BACKUP LOG', 'RESTORE LOG') 