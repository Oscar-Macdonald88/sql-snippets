-- Check status of Always On automatic seeding restore

-- Primary

SELECT

r.session_id,r.status,r.command,r.wait_type

,r.percent_complete,r.estimated_completion_time

FROM sys.dm_exec_requests r JOIN sys.dm_exec_sessions s

ON r.session_id=s.session_id

WHERE r.session_id<>@@SPID

AND s.is_user_process=0

AND r.command like 'VDI%'

and wait_type='BACKUPTHREAD'

-- Secondary

SELECT

 r.session_id, r.status, r.command, r.wait_type

 , r.percent_complete, r.estimated_completion_time

FROM sys.dm_exec_requests r JOIN sys.dm_exec_sessions s

 ON r.session_id = s.session_id

WHERE r.session_id <> @@SPID

AND s.is_user_process = 0

AND r.command like 'REDO%'

and wait_type ='BACKUPTHREAD'