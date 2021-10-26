--Move a Database Data and/or Log files (no server restart)
	USE [master]
	GO
	DECLARE @NewDataLocation NVARCHAR(1024), @NewLogLocation NVARCHAR(1024)
	SELECT --SET: Your NEW locations!
		@NewDataLocation = 'C:\MSSQL\SQL2014\TemporaryMigration\SQLData', --Trailing Backslash critical
		@NewLogLocation = 'C:\MSSQL\SQL2014\TemporaryMigration\SQLLogs\'; --Trailing Backslash critical
 
	IF RIGHT(@NewDataLocation, 1) <> '\'
		set @NewDataLocation = @NewDataLocation + '\';
	IF RIGHT(@NewLogLocation, 1) <> '\'
		set @NewLogLocation = @NewLogLocation + '\';
 
	SELECT 
		DB_NAME(dbid) AS [Database],
		filename,
		REVERSE(LEFT(REVERSE(filename),CHARINDEX('\', REVERSE(filename), 1) - 1)) [file_name],
		'' AS [-],
		'ALTER DATABASE ['+DB_NAME(dbid)+'] SET OFFLINE WITH ROLLBACK IMMEDIATE;' AS [1_Set_Offline],
		'ALTER DATABASE ['+DB_NAME(dbid)+'] MODIFY FILE ( NAME = [' + name + '], FILENAME = ''' + CASE WHEN (groupid = 0) THEN @NewLogLocation ELSE @NewDataLocation END + REVERSE(LEFT(REVERSE(filename),CHARINDEX('\', REVERSE(filename), 1) - 1)) + ''' ); ' AS [2_Change_Location],
		'EXEC xp_cmdshell ''robocopy "'+LEFT(filename, LEN(filename) - CHARINDEX('\', REVERSE(filename), 1))+'" "' + CASE WHEN (groupid = 0) THEN LEFT(@NewLogLocation, LEN(@NewLogLocation)-1) ELSE LEFT(@NewDataLocation, LEN(@NewDataLocation)-1) END + '" "'+REVERSE(LEFT(REVERSE(filename),CHARINDEX('\', REVERSE(filename), 1) - 1))+'" /E /V /MT:0 /W:0 /R:0'';' AS [3_Copy_File],
		'EXEC xp_cmdshell ''DIR /B "' + CASE WHEN (groupid = 0) THEN @NewLogLocation ELSE @NewDataLocation END + ''+REVERSE(LEFT(REVERSE(filename),CHARINDEX('\', REVERSE(filename), 1) - 1))+'"'';' AS [4_Verify_Copy],
		'ALTER DATABASE ['+DB_NAME(dbid)+'] SET ONLINE;' AS [5_Set_Online],
		'EXEC xp_cmdshell ''DEL "'+filename+'"''' AS [6_Delete_Originals]
	FROM sys.sysaltfiles
	WHERE DB_NAME(dbid) IN ( --SET: Your target databases here! 
		'TestTest',
		'LcsCDR2016y',
		'LcsLog2016z'
	)
	ORDER BY groupid, DB_NAME(dbid);