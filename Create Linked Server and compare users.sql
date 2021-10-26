DECLARE @LinkedServer nvarchar(max), 
@DataSource nvarchar(max),
@sql nvarchar(max); 
SET @LinkedServer = ''; -- EDIT THIS! name of the linked server to create

-- create a temporary linked server, in order to compare the logins between instances.
USE [master]
GO
EXEC master.dbo.sp_addlinkedserver @server = @LinkedServer, @srvproduct=N'SQL Server';
GO
EXEC master.dbo.sp_addlinkedsrvlogin   
    @rmtsrvname = @LinkedServer,   
    @locallogin = NULL ,   
    @useself = N'True' ;  
GO 
/*
Selects all server principals from this instance (sp) and compares it with all logins from the linked instance (l)
where the names match, but the SID does not match
*/
set @sql = 'SELECT sp.[name], sp.[sid] as [Origin Server SID], l.[sid] as [Linked Server SID], 
sp.is_disabled, sp.default_database_name, sp.default_language_name
FROM ['+@LinkedServer+'].master.sys.server_principals AS sp
LEFT JOIN master.sys.sql_logins AS l ON sp.[name]=l.[name]
where sp.[name] = l.[name] and sp.[sid] <> l.[sid]
AND sp.[type] IN (''U'', ''G'', ''S'') 
AND
      UPPER(sp.[name]) NOT LIKE ''NT SERVICE\%'' 
	  and UPPER(sp.[name]) NOT LIKE''##MS_%'' 
	  AND
	  sp.[name] NOT IN (''NT AUTHORITY\SYSTEM'')'

-- execute the constructed SQL
EXECUTE master.sys.sp_executesql @sql;
GO

-- drop the temp linked server.
USE [master]
GO
EXEC master.dbo.sp_dropserver @server = @LinkedServer;
GO
