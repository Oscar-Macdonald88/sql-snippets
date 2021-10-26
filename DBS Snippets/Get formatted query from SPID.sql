-- Get the formatted, plain text query from a SPID.
	DECLARE @query VARCHAR(MAX)
	SELECT @query = (SELECT text FROM sys.dm_exec_sql_text(sql_handle)) 
	FROM sys.dm_exec_requests r
	WHERE session_id = 98	--ENTER SPID HERE!
	PRINT @query