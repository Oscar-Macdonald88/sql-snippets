--Review Default Trace for Login Failures
	SELECT
		t.SessionLoginName,
		t.DatabaseName,
		t.HostName,
		t.ApplicationName,
		MIN(t.StartTime) AS [Oldest],
		MAX(t.StartTime) AS [Newest],
		COUNT(*) AS [Count],
		'' AS [-],
		'PRINT CHAR(13)+CHAR(10)+''Login: '+t.SessionLoginName+' ('+CONVERT(VARCHAR(25), COUNT(*))+' failures)''+CHAR(13)+CHAR(10)+'''
		+'Database: '+t.DatabaseName+'''+CHAR(13)+CHAR(10)+'''
		+'Hostname: '+t.HostName+'''+CHAR(13)+CHAR(10)+'''
		+'Application: '+t.ApplicationName+'''+CHAR(13)+CHAR(10)+'''
		+'Oldest failure: '+CONVERT(VARCHAR(25), MIN(t.StartTime))+'''+CHAR(13)+CHAR(10)+'''
		+'Latest failure: '+CONVERT(VARCHAR(25), MAX(t.StartTime))+'''+CHAR(13)+CHAR(10)' AS [CW_Message]
	FROM sys.fn_trace_gettable(CONVERT(VARCHAR(500), (SELECT TOP 1 f.[value] FROM sys.fn_trace_getinfo(NULL) f WHERE f.property = 2)), DEFAULT) t
		JOIN sys.trace_events te ON (t.EventClass = te.trace_event_id)
	WHERE 
		te.name IN ('Audit Login Failed')
		AND t.ServerName = SERVERPROPERTY('ServerName')
		AND t.StartTime > DATEADD(DAY, -1, GETDATE())
	GROUP BY 
		t.HostName,
		t.SessionLoginName,
		t.DatabaseName,
		t.ApplicationName
	ORDER BY [Count] DESC
 
	SELECT SSLDBA.dbo.GetParamInt('LoginFailureThreshold') AS [LoginFailureThreshold]
	--EXEC SSLDBA.dbo.up_SetParamInt 'LoginFailureThreshold', 50
 
 
--Darryn's code: Review Default Trace for Login Failures
	SELECT  
		TE.name AS [EventName] ,
		V.subclass_name,
		T.DatabaseName,
		T.DatabaseID,
		T.NTDomainName,
		T.ApplicationName,
		T.LoginName,
		T.SPID,
		T.StartTime,
		T.SessionLoginName,
		T.HostName,
		T.ServerName
	FROM sys.fn_trace_gettable(CONVERT(VARCHAR(150), (SELECT TOP 1 f.[value] FROM sys.fn_trace_getinfo(NULL) f WHERE f.property = 2)), DEFAULT) T
		JOIN sys.trace_events TE ON (T.EventClass = TE.trace_event_id)
		JOIN sys.trace_subclass_values V ON (V.trace_event_id = TE.trace_event_id)
		AND V.subclass_value = T.EventSubClass
	WHERE TE.name IN ('Audit Login Failed')