-- new tool
with spids as (
	select p.spid,
		db_name(p.dbid) as db_name,
		suser_sname(p.sid) as username,
		p.nt_username,
		p.loginame,
		p.hostname,
		case
			when (p.program_name like '%Job 0x%') then 'SQLAgent - Agent Job: "' + (
				select top 1 name
				FROM msdb.dbo.sysjobs
				where p.program_name like '%' + master.dbo.fn_varbintohexstr(job_id) + '%'
			) + '"'
			else p.program_name
		end program_name,
		p.cmd,
		t.text,
		p.status,
		p.blocked,
		p.waittime,
		p.lastwaittype,
		p.waitresource,
		p.cpu,
		p.physical_io,
		p.memusage,
		p.login_time,
		p.last_batch,
		p.open_tran
	from sys.sysprocesses p
		cross apply sys.dm_exec_sql_text(p.sql_handle) as t
)
select p.spid,
	db_name(p.dbid) as db_name,
	suser_sname(p.sid) as username,
	p.nt_username,
	p.loginame,
	p.hostname,
	case
		when (p.program_name like '%Job 0x%') then 'SQLAgent - Agent Job: "' + (
			select top 1 name
			FROM msdb.dbo.sysjobs
			where p.program_name like '%' + master.dbo.fn_varbintohexstr(job_id) + '%'
		) + '"'
		else p.program_name
	end,
	p.cmd,
	t.text,
	p.status,
	p.blocked,
	p.waittime,
	p.lastwaittype,
	p.waitresource,
	p.cpu,
	p.physical_io,
	p.memusage,
	p.login_time,
	p.last_batch,
	p.open_tran
from sys.sysprocesses p
	cross apply sys.dm_exec_sql_text(p.sql_handle) as t
where p.spid in (
		select blocked
		from spids
	)
	or p.blocked <> 0
order by p.blocked 

-- https://docs.microsoft.com/en-us/troubleshoot/sql/performance/understand-resolve-blocking#gather-information-from-dmvs
	/*
	 WITH cteHead ( session_id,request_id,wait_type,wait_resource,last_wait_type,is_user_process,request_cpu_time
	 ,request_logical_reads,request_reads,request_writes,wait_time,blocking_session_id,memory_usage
	 ,session_cpu_time,session_reads,session_writes,session_logical_reads
	 ,percent_complete,est_completion_time,request_start_time,request_status,command
	 ,plan_handle,sql_handle,statement_start_offset,statement_end_offset,most_recent_sql_handle
	 ,session_status,group_id,query_hash,query_plan_hash) 
	 AS ( SELECT sess.session_id, req.request_id, LEFT (ISNULL (req.wait_type, ''), 50) AS 'wait_type'
	 , LEFT (ISNULL (req.wait_resource, ''), 40) AS 'wait_resource', LEFT (req.last_wait_type, 50) AS 'last_wait_type'
	 , sess.is_user_process, req.cpu_time AS 'request_cpu_time', req.logical_reads AS 'request_logical_reads'
	 , req.reads AS 'request_reads', req.writes AS 'request_writes', req.wait_time, req.blocking_session_id,sess.memory_usage
	 , sess.cpu_time AS 'session_cpu_time', sess.reads AS 'session_reads', sess.writes AS 'session_writes', sess.logical_reads AS 'session_logical_reads'
	 , CONVERT (decimal(5,2), req.percent_complete) AS 'percent_complete', req.estimated_completion_time AS 'est_completion_time'
	 , req.start_time AS 'request_start_time', LEFT (req.status, 15) AS 'request_status', req.command
	 , req.plan_handle, req.[sql_handle], req.statement_start_offset, req.statement_end_offset, conn.most_recent_sql_handle
	 , LEFT (sess.status, 15) AS 'session_status', sess.group_id, req.query_hash, req.query_plan_hash
	 FROM sys.dm_exec_sessions AS sess
	 LEFT OUTER JOIN sys.dm_exec_requests AS req ON sess.session_id = req.session_id
	 LEFT OUTER JOIN sys.dm_exec_connections AS conn on conn.session_id = sess.session_id 
	 )
	 , cteBlockingHierarchy (head_blocker_session_id, session_id, blocking_session_id, wait_type, wait_duration_ms,
	 wait_resource, statement_start_offset, statement_end_offset, plan_handle, sql_handle, most_recent_sql_handle, [Level])
	 AS ( SELECT head.session_id AS head_blocker_session_id, head.session_id AS session_id, head.blocking_session_id
	 , head.wait_type, head.wait_time, head.wait_resource, head.statement_start_offset, head.statement_end_offset
	 , head.plan_handle, head.sql_handle, head.most_recent_sql_handle, 0 AS [Level]
	 FROM cteHead AS head
	 WHERE (head.blocking_session_id IS NULL OR head.blocking_session_id = 0)
	 AND head.session_id IN (SELECT DISTINCT blocking_session_id FROM cteHead WHERE blocking_session_id != 0)
	 UNION ALL
	 SELECT h.head_blocker_session_id, blocked.session_id, blocked.blocking_session_id, blocked.wait_type,
	 blocked.wait_time, blocked.wait_resource, h.statement_start_offset, h.statement_end_offset,
	 h.plan_handle, h.sql_handle, h.most_recent_sql_handle, [Level] + 1
	 FROM cteHead AS blocked
	 INNER JOIN cteBlockingHierarchy AS h ON h.session_id = blocked.blocking_session_id and h.session_id!=blocked.session_id --avoid infinite recursion for latch type of blocking
	 WHERE h.wait_type COLLATE Latin1_General_BIN NOT IN ('EXCHANGE', 'CXPACKET') or h.wait_type is null
	 )
	 SELECT bh.*, txt.text AS blocker_query_or_most_recent_query 
	 FROM cteBlockingHierarchy AS bh 
	 OUTER APPLY sys.dm_exec_sql_text (ISNULL ([sql_handle], most_recent_sql_handle)) AS txt;
	 */
	-- Old Blocking tool
	/*
	 DECLARE @sp_who2 
	 TABLE(
	 SPID INT
	 , Status VARCHAR(MAX) --INT
	 , LOGIN VARCHAR(MAX)
	 , HostName VARCHAR(MAX)
	 , BlkBy VARCHAR(MAX)
	 , DBName VARCHAR(MAX)
	 , Command VARCHAR(MAX)
	 , CPUTime INT
	 , DiskIO VARCHAR(MAX)
	 , LastBatch VARCHAR(MAX)
	 , ProgramName VARCHAR(MAX)
	 , SPID_1 INT,
	 REQUESTID INT)
	 INSERT INTO @sp_who2 EXEC sp_who2
	 
	 update @sp_who2 set ProgramName = case when (ProgramName like '%Job 0x%') then 'SQLAgent - Agent Job: "' + (select top 1 name FROM msdb.dbo.sysjobs where ProgramName like '%'+master.dbo.fn_varbintohexstr(job_id)+'%') + '"' else ProgramName end;
	 
	 SELECT sp.SPID, sp.Status, sp.[LOGIN], sp.HostName, sp.BlkBy, sp.DBName, sp.Command, sp.ProgramName, der.start_time, sp.LastBatch, der.text, '' AS [---], 'KILL '+CONVERT(VARCHAR(32),sp.SPID) AS [T-SQL]
	 FROM @sp_who2 sp
	 LEFT JOIN (
	 SELECT der.session_id, der.start_time, der.status, der.command, dest.text 
	 FROM master.sys.dm_exec_requests der 
	 CROSS APPLY master.sys.dm_exec_sql_text(der.sql_handle) dest 
	 WHERE der.session_id IN (
	 SELECT SPID FROM @sp_who2
	 WHERE BlkBy NOT LIKE '%.%' 
	 OR SPID IN (SELECT BlkBy FROM @sp_who2 WHERE BlkBy NOT LIKE '%.%')
	 )
	 ) der ON (sp.SPID=der.session_id)
	 WHERE sp.BlkBy NOT LIKE '%.%' 
	 OR sp.SPID IN (SELECT BlkBy FROM @sp_who2 WHERE BlkBy NOT LIKE '%.%')
	 ORDER BY sp.BlkBy
	 */