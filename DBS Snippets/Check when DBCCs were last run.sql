--Check the last time DBCC Checks were run against the databases
	CREATE TABLE #DBInfo (ParentObject VARCHAR(255), [Object] VARCHAR(255), Field VARCHAR(255), [Value] VARCHAR(255))
	CREATE TABLE #Value (DatabaseName VARCHAR(255), LastDBCCCheckDB DATETIME);
	EXECUTE sp_MSforeachdb '
		--Insert results of DBCC DBINFO into temp table, transform into simpler table with database name and datetime of last known good DBCC CheckDB
		INSERT INTO #DBInfo EXECUTE (''DBCC DBINFO ( ''''?'''' ) WITH TABLERESULTS'');
		INSERT INTO #Value (DatabaseName, LastDBCCCheckDB) (SELECT ''?'', [Value] FROM #DBInfo WHERE Field = ''dbi_dbccLastKnownGood'');
		TRUNCATE TABLE #DBInfo;
	';
	SELECT
		DB_NAME(db.database_id) AS [DatabaseName],
		convert(bigint, mfrows.RowSize) * 8 / 1024 AS [RowSizeMB],
		--tdb.WeeklyDBCC,
		v.LastDBCCCheckDB,
		CONVERT(VARCHAR(20), DATEDIFF(DAY, v.LastDBCCCheckDB, GETDATE())) + case when (v.LastDBCCCheckDB < getdate()-7) then ' *' else '' end AS [Age]
	FROM sys.databases db
	LEFT JOIN (SELECT database_id, SUM(size) AS [RowSize] FROM sys.master_files WHERE type = 0 GROUP BY database_id, type) mfrows ON (mfrows.database_id = db.database_id)
	LEFT JOIN #Value v ON (v.DatabaseName = DB_NAME(db.database_id))
	ORDER BY DatabaseName;
	DROP TABLE #DBInfo;
	DROP TABLE #Value;