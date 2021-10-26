



DECLARE @DatabaseName VARCHAR(40)
DECLARE @DatabaseID Int

SET @DatabaseName = 'WSS_ContentProduction'

SET @DatabaseID = (SELECT Database_ID FROM sys.databases where name = @DatabaseName )


SELECT	DatabaseID,
		F_OB.ObjectID,
		SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1,  
				((CASE statement_end_offset   
				  WHEN -1 THEN DATALENGTH(ST.text)  
				  ELSE QS.statement_end_offset 
				  END- QS.statement_start_offset)/2) + 1) AS statement_text , 
		ISNULL(DB_Name(DatabaseID),
		CASE DatabaseID WHEN 32767 THEN 'Internal ResourceDB' ELSE CONVERT(varchar(255),DatabaseID)end) AS [DatabaseName], 
		SUM(total_worker_time) AS [CPU Time Ms],
		SUM(total_logical_reads)  AS [Logical Reads],
		SUM(total_logical_writes)  AS [Logical Writes],
		SUM(total_logical_reads+total_logical_writes)  AS [Logical IO],
		SUM(total_physical_reads)  AS [Physical Reads],
		SUM(total_elapsed_time)  AS [Duration MicroSec],
		SUM(total_clr_time)  AS [CLR Time MicroSec],
		SUM(total_rows)  AS [Rows Returned],
		SUM(execution_count)  AS [Execution Count],
		COUNT(*) 'Plan Count'
INTO #TempDB_CPU_Stats
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY (
			SELECT CONVERT(int, value) AS [DatabaseID] 
			FROM sys.dm_exec_plan_attributes(qs.plan_handle)
			WHERE attribute = N'dbid') AS F_DB
CROSS APPLY (
			SELECT CONVERT(int, value) AS [ObjectID] 
			FROM sys.dm_exec_plan_attributes(qs.plan_handle)
			WHERE attribute = N'objectID') AS F_OB
CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) as ST
WHERE DatabaseID = @DatabaseID 
GROUP BY DatabaseID,F_OB.ObjectID,SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1,  
									((CASE statement_end_offset   
										WHEN -1 THEN DATALENGTH(ST.text)  
										ELSE QS.statement_end_offset END - QS.statement_start_offset)/2) + 1)


SELECT  TOP 10 
		ROW_NUMBER() OVER(ORDER BY [CPU Time Ms] DESC) AS [Rank CPU],
		DatabaseName,
		OBJECTID,
		statement_text,
		--CASE WHEN [CPU Time Ms] = 0 THEN '0' 
		--	ELSE CONVERT(decimal(15,2),([CPU Time Ms]/1000.0)/3600)  
		--END AS [CPU Time Hr], 
		CASE WHEN [CPU Time Ms]= 0 THEN '0'
			ELSE CAST([CPU Time Ms] * 1.0 / SUM([CPU Time Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) 
		END AS [CPU Percent],
		--CASE WHEN [Duration MicroSec]= 0 THEN '0'
		--	ELSE  CONVERT(decimal(15,2),([Duration MicroSec]/1000000.0)/3600)
		--END AS [Duration MicroSec] ,
		--CASE WHEN [Duration MicroSec]= 0 THEN '0'
		--	ELSE CAST([Duration MicroSec] * 1.0 / SUM([Duration MicroSec]) OVER() * 100.0 AS DECIMAL(5, 2)) 
		--END AS [Duration Percent],    
		--[Logical Reads],
		--CASE WHEN [Logical Reads]= 0 THEN '0'
		--	 ELSE CAST([Logical Reads] * 1.0 / SUM([Logical Reads]) OVER() * 100.0 AS DECIMAL(5, 2)) 
		--END AS [Logical Reads Percent],      
		--[Rows Returned],
		--CASE WHEN [Rows Returned]= 0 THEN '0'
		--	 ELSE CAST([Rows Returned] * 1.0 / SUM([Rows Returned]) OVER() * 100.0 AS DECIMAL(5, 2)) 
		--END AS [Rows Returned Percent],
		--[Reads Per Row Returned] = [Logical Reads]/[Rows Returned],
		--[Execution Count],
		--CASE WHEN [Execution Count]= 0 THEN '0'
		--	 ELSE CAST([Execution Count] * 1.0 / SUM([Execution Count]) OVER() * 100.0 AS DECIMAL(5, 2)) 
		--END AS [Execution Count Percent],
		[Physical Reads],
		--CASE WHEN [Physical Reads] = 0 THEN '0'
		--	 ELSE CAST([Physical Reads] * 1.0 / SUM([Physical Reads]) OVER() * 100.0 AS DECIMAL(5, 2)) 
		--END AS [Physcal Reads Percent], 
		--[Logical Writes],
		--CASE WHEN [Logical Writes] = 0 THEN '0'
		--	 ELSE CAST([Logical Writes] * 1.0 / SUM([Logical Writes]) OVER() * 100.0 AS DECIMAL(5, 2)) 
		--END AS [Logical Writes Percent],
		--[Logical IO],
		--CASE WHEN [Logical IO] = 0 THEN '0'
		--	 ELSE CAST([Logical IO] * 1.0 / SUM([Logical IO]) OVER() * 100.0 AS DECIMAL(5, 2)) 
		--END AS [Logical IO Percent],
		--[CLR Time MicroSec],
		--CASE WHEN [CLR Time MicroSec] = 0 THEN '0'
		--	 ELSE CAST([CLR Time MicroSec] * 1.0 / SUM(case [CLR Time MicroSec] when 0 then 1 else [CLR Time MicroSec] end ) OVER() * 100.0 AS DECIMAL(5, 2))
	 --   END AS [CLR Time Percent],
		[CPU Time Ms],
		[CPU Time Ms]/1000 [CPU Time Sec],
		[Duration MicroSec],
		[Duration MicroSec]/1000000 [Duration Sec]
FROM #TempDB_CPU_Stats 
WHERE DatabaseID = @DatabaseID 
ORDER BY [Rank CPU] OPTION (RECOMPILE)

DROP TABLE #TempDB_CPU_Stats
