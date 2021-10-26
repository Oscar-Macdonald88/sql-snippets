-- Jonathans Trace file merger and filter
SELECT CAST(value as NVARCHAR(500))as value INTO #Trace FROM sys.fn_trace_getinfo(0) WHERE property = 2
DECLARE @Path NVARCHAR(MAX) = (SELECT TOP(1) value FROM #Trace)
SELECT * INTO #TraceInfo FROM ::fn_trace_gettable(@Path ,DEFAULT)
--SELECT COUNT(*) AS 'Trace files found' FROM #Trace 
DELETE TOP(1) FROM #Trace
WHILE EXISTS(SELECT * FROM #Trace) BEGIN
	SET @Path = (SELECT TOP(1) value FROM #Trace)
	INSERT INTO #TraceInfo SELECT * FROM ::fn_trace_gettable(@Path ,DEFAULT)
	DELETE TOP(1) FROM #Trace
END
 
SELECT TOP(1000) StartTime AS 'TimeStamp', trcev.name AS 'Event Name', trc.* FROM #TraceInfo trc LEFT JOIN sys.trace_events trcev ON EventClass = trace_event_id
WHERE 1=1
--AND ClientProcessID = 2328 AND SPID = 61
--AND eventclass = 45
--AND SPID = 61
--AND ClientProcessID = 2328
--AND trcev.name =
--Date setup: CONVERT(VARCHAR, CONVERT(DATE, GETDATE())) + ' 05:10:00' or '2018-06-21 05:10:00'
--AND StartTime >= CONVERT(datetime,CONVERT(VARCHAR, CONVERT(DATE, GETDATE())) + ' 10:10:00') --StartTime After
--AND StartTime <= CONVERT(datetime,CONVERT(VARCHAR, CONVERT(DATE, GETDATE())) + ' 10:15:00') --StartTime Before 
ORDER BY StartTime DESC
 
DROP TABLE #Trace
DROP TABLE #TraceInfo
 
/*
Get all trace events
SELECT trace_event_id AS 'eventclass', name FROM sys.trace_events WHERE name LIKE '%%' ORDER BY trace_event_id ASC
 
*/

/*
Popular trace events
 
EventID  Event_Description
-------  ----------------------------------------------
18       Audit Server Starts And Stops
20       Audit Login Failed
22       ErrorLog
46       Object:Created
47       Object:Deleted
55       Hash Warning
69       Sort Warnings
79       Missing Column Statistics
80       Missing Join Predicate
81       Server Memory Change
92       Data File Auto Grow
93       Log File Auto Grow
94       Data File Auto Shrink
95       Log File Auto Shrink
102      Audit Database Scope GDR Event
103      Audit Schema Object GDR Event
104      Audit Addlogin Event
105      Audit Login GDR Event
106      Audit Login Change Property Event
108      Audit Add Login to Server Role Event
109      Audit Add DB User Event
110      Audit Add Member to DB Role Event
111      Audit Add Role Event
115      Audit Backup/Restore Event
116      Audit DBCC Event
117      Audit Change Audit Event
152      Audit Change Database Owner
153      Audit Schema Object Take Ownership Event
155      FT:Crawl Started
156      FT:Crawl Stopped
164      Object:Altered
167      Database Mirroring State Change
175      Audit Server Alter Trace Event
218      Plan Guide Unsuccessful
*/