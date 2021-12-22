IF (SELECT CONVERT(INT,value_in_use) FROM sys.configurations WHERE name = 'default trace enabled') = 1
	BEGIN 
		DECLARE @tracefile VARCHAR(2000);
 		SELECT @tracefile = path FROM sys.traces WHERE is_default = 1;
		SET @tracefile = LEFT(@tracefile,LEN(@tracefile) - PATINDEX('%\%', REVERSE(@tracefile))) + '\log.trc'; 
		SELECT
			ServerName AS [SQL_Instance],
			DatabaseName AS [Database_Name],
			[FileName] AS [Logical_File_Name],
			(Duration/1000) AS [Duration_MS],
			CONVERT(VARCHAR(50),StartTime, 100) AS [Start_Time],
			CAST((IntegerData*8.0/1024) AS DECIMAL(19,2)) AS [Change_In_Size_MB],
			'---------------',
			*
		FROM ::fn_trace_gettable(@tracefile, default)
		WHERE 
			EventClass >= 92
			AND EventClass <= 95
			--AND DatabaseName = 'tempdb'				--SET DB HERE!
		ORDER BY StartTime DESC;  
	END