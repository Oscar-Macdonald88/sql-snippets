/*Author:RH/GT  Date:02/2014  Version:1
This script should find the default trace file and open it with the select criterea you set from the 'Pick and Mix' list below, 
or whatever else you choose to add.*/ 

Declare @DefaultTraceFile Varchar (255)
SET @DefaultTraceFile = 
(SELECT CAST(value as Varchar(max))
FROM [fn_trace_getinfo](NULL) 
WHERE [property] = 2
AND traceid = 1)

select te.name as EventClass, t.DatabaseName, t.FileName, t.StartTime, t.ApplicationName, t.LoginName, t.SPID, TextData
From fn_trace_gettable(@DefaultTraceFile, NULL) AS t
INNER JOIN sys.trace_events AS te ON t.EventClass = te.trace_event_id
Where
--te.name like '%Auto Grow'
--AND
--LoginName = '??????'
--AND									-->	Pick and choose as appropriate or modify
t.TextData IS NOT NULL--LIKE 'BACKUP%'
--AND
--t.DatabaseName = 'tempdb'	
--AND	
--StartTime Between '2014-02-14' AND '2014-02-18' --<<amend to suit
ORDER BY StartTime DESC

--SELECT job_id, name from msdb.dbo.sysjobs
--WHERE Job_id LIKE '%????????????'--<< Copy and Paste last 12 characters of the uniqueidentifier from JobStep under the ApplicationName column 
								   --into the Like name leaving the % in place, to confirm the Agent job running the query.


-- Alternative

/*
--Query the default trace
DECLARE @defaultTrace NVARCHAR(4000), @start VARCHAR(32), @end VARCHAR(32)
SELECT TOP 1 @defaultTrace = CONVERT(NVARCHAR(4000), [value]) FROM [fn_trace_getinfo](NULL) WHERE [property] = 2 
SELECT @defaultTrace = LEFT(@defaultTrace, LEN(@defaultTrace)-CHARINDEX('_', REVERSE(@defaultTrace)))+'.trc'

SELECT 
	@start = '2022-03-28 15:20:45.053'    --VARIABLE: Replace this with a String: EG '2021-08-26 01:57:45.053'
	, @end = '2022-03-28 15:50:45.053'                        --VARIABLE: Replace this with a String: EG '2021-08-26 01:57:45.053'

	PRINT 'Default Trace: '+@defaultTrace+CHAR(13)+CHAR(13)+CHAR(9)+CHAR(9)+'@start = '''+@start+''''+CHAR(13)+CHAR(9)+CHAR(9)+', @end = '''+@end+''''

SELECT TOP 1000 
StartTime, *  
FROM [fn_trace_gettable](@defaultTrace, DEFAULT) 
WHERE StartTime BETWEEN @start AND @end
	--AND TextData LIKE 'BACKUP%'            --VARIABLE: Uncomment this line to search
ORDER BY 1;
*/