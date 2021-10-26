set nocount on

--Change Database owner to SA
declare @SSL_helpDB table (
	name varchar(200),
	size varchar(20),
	owner varchar(50),
	dbid int,
	created datetime,
	status varchar(4000),
	compat int
	);

insert @SSL_helpDB
exec sp_helpdb;

select 'Databases on ' + @@SERVERNAME + ' without SA owner:' as 'Name',
	'' as 'Owner',
	'SELECT DB_NAME(dbid) AS ''DBName'', loginame INTO #TEMP FROM sys.sysprocesses' as 'TSQL'

union all

select sdb.name,
	hdb.owner,
	'IF((SELECT COUNT(*) FROM #TEMP WHERE [loginame] = ''' + hdb.owner + ''' AND DBName = ''' + sdb.name + ''') = 0)BEGIN USE ' + QUOTENAME(sdb.name) + ' exec sp_changedbowner @loginame =''sa'' CREATE USER [' + hdb.owner + '] FOR LOGIN [' + hdb.owner + '] EXEC sp_addrolemember @rolename = [db_owner], @membername = [' + hdb.owner + '] SELECT ''Completed for ' + sdb.name + ''' AS ''Success!'' END ELSE BEGIN SELECT ''Owner currently has active connection'' AS ''!!Warning!!'', * FROM #TEMP WHERE [loginame] = ''' + hdb.owner + ''' AND DBName = ''' + sdb.name + ''' END USE master'
from sys.databases sdb
inner join @SSL_helpDB hdb on sdb.name = hdb.name
where sdb.database_id > 4
	and sdb.is_read_only = 0
	and hdb.owner != 'sa'
	and (
		select DATABASEPROPERTYEX(sdb.name, 'Updateability')
		) = 'READ_WRITE'

union all

select '',
	'',
	'DROP TABLE #TEMP'
