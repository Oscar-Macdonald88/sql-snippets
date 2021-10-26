SELECT te.name, t.DatabaseName, t.FileName, t.StartTime, t.ApplicatioNname 
FROM fn_trace_gettable('C:\Program Files\Microsoft SQL Server\MSSQL.3\MSSQL\LOG\log_331.trc', NULL) AS t 
INNER JOIN sys.trace_events AS te ON t.EventClass = te.trace_event_id 
WHERE te.name LIKE '%Auto Grow' 
ORDER BY StartTime DESC
