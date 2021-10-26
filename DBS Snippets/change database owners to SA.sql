SET NOCOUNT ON
--Change Database owner to SA
DECLARE @SSL_helpDB TABLE (name VARCHAR(200), size VARCHAR(20), owner VARCHAR(50), dbid INT, created DATETIME, status VARCHAR(4000), compat INT); INSERT @SSL_helpDB EXEC sp_helpdb;
SELECT 'Databases on ' + @@SERVERNAME + ' without SA owner:' AS 'Name','' AS 'Owner','--:CONNECT ' + @@SERVERNAME AS 'TSQL' UNION ALL --REMOVE '--' for SQLCMD
SELECT 'Setup TSQL --->', '', 'SELECT DB_NAME(dbid) AS ''DBName'', status, loginame INTO #TEMP FROM sys.sysprocesses' UNION ALL
SELECT sdb.name, hdb.owner, 'IF((SELECT COUNT(*) FROM #TEMP WHERE status != ''sleeping'' and [loginame] = ''' + hdb.owner + ''' AND DBName = ''' + sdb.name + ''') = 0)BEGIN USE '+QUOTENAME(sdb.name)+ ' exec sp_changedbowner @loginame =''sa'' CREATE USER [' + hdb.owner + '] FOR LOGIN [' + hdb.owner + '] EXEC sp_addrolemember @rolename = [db_owner], @membername = [' + hdb.owner + '] SELECT ''Completed for ' + sdb.name + ''' AS ''Success!'' END ELSE BEGIN SELECT ''Owner currently has active connection'' AS ''!!Warning!!'', * FROM #TEMP WHERE [loginame] = ''' + hdb.owner + ''' AND DBName = ''' + sdb.name + ''' END USE master' FROM sys.databases sdb INNER JOIN @SSL_helpDB hdb ON sdb.name = hdb.name WHERE sdb.database_id>4 AND sdb.is_read_only = 0 AND hdb.owner != 'sa' AND (SELECT DATABASEPROPERTYEX(sdb.name, 'Updateability')) = 'READ_WRITE' UNION ALL
SELECT 'Cleanup TSQL --->','','DROP TABLE #TEMP' UNION ALL
SELECT 'GO --->','','GO'