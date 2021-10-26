--Kill SPIDs within a database.
	DECLARE @kill NVARCHAR(MAX);
	SELECT @kill = COALESCE(@kill + '; ', '') + 'KILL '+CONVERT(NVARCHAR(20), spid)
	FROM master.dbo.sysprocesses WITH (NOLOCK)
	WHERE spid > 50 AND DB_NAME(dbid) = ''; --EDIT: Set this!
	PRINT @kill;
	--EXEC sp_executesql @kill; --EDIT: Uncomment this prior to running!