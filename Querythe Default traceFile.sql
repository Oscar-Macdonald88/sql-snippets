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
