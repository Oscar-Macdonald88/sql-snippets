SELECT 
  LEFT (p.cacheobjtype + ' (' + p.objtype + ')', 35) AS cacheobjtype,
  p.usecounts, p.size_in_bytes / 1024 AS size_in_kb, 
  PlanStats.total_worker_time/1000 AS tot_cpu_ms, PlanStats.total_elapsed_time/1000 AS tot_duration_ms, 
  PlanStats.total_physical_reads, PlanStats.total_logical_writes, PlanStats.total_logical_reads,
  PlanStats.CpuRank, PlanStats.PhysicalReadsRank, PlanStats.DurationRank, 
  LEFT (CASE 
    WHEN pa.value=32767 THEN 'ResourceDb' 
    ELSE ISNULL (DB_NAME (CONVERT (sysname, pa.value)), CONVERT (sysname,pa.value))
  END, 40) AS dbname,
  sql.objectid, 
  OBJECT_NAME(sql.objectid,sql.dbid) AS procname, 
  REPLACE (REPLACE (SUBSTRING (sql.[text], PlanStats.statement_start_offset/2 + 1, 
      CASE WHEN PlanStats.statement_end_offset = -1 THEN LEN (CONVERT(nvarchar(max), sql.[text])) 
        ELSE PlanStats.statement_end_offset/2 - PlanStats.statement_start_offset/2 + 1
      END), CHAR(13), ' '), CHAR(10), ' ') AS stmt_text,
  qp.query_plan
FROM 
(
  SELECT 
    stat.plan_handle, statement_start_offset, statement_end_offset, 
    stat.total_worker_time, stat.total_elapsed_time, stat.total_physical_reads, 
    stat.total_logical_writes, stat.total_logical_reads, 
    ROW_NUMBER() OVER (ORDER BY stat.total_worker_time DESC) AS CpuRank, 
    ROW_NUMBER() OVER (ORDER BY stat.total_physical_reads DESC) AS PhysicalReadsRank, 
    ROW_NUMBER() OVER (ORDER BY stat.total_elapsed_time DESC) AS DurationRank 
  FROM sys.dm_exec_query_stats stat 
) AS PlanStats 
INNER JOIN sys.dm_exec_cached_plans p ON p.plan_handle = PlanStats.plan_handle 
OUTER APPLY sys.dm_exec_plan_attributes (p.plan_handle) pa 
OUTER APPLY sys.dm_exec_sql_text (p.plan_handle) AS sql
OUTER APPLY sys.dm_exec_query_plan(p.plan_handle) AS qp
WHERE (PlanStats.CpuRank < 50 OR PlanStats.PhysicalReadsRank < 50 OR PlanStats.DurationRank < 50)
  AND pa.attribute = 'dbid' 
ORDER BY tot_cpu_ms DESC