drop table if exists #OrphanedUsers

create table #OrphanedUsers
(ServerName nvarchar(255),
databasename nvarchar(255),
username nvarchar(255)
)

DECLARE @command varchar(1000) ='USE [?] if exists (select top 1 dp.name FROM sys.database_principals AS dp LEFT JOIN sys.server_principals AS sp ON dp.sid = sp.sid WHERE sp.sid IS NULL AND dp.authentication_type_desc = ''INSTANCE'') begin SELECT convert(nvarchar(255),SERVERPROPERTY(''servername'')), ''?'', dp.name AS user_name FROM sys.database_principals AS dp LEFT JOIN sys.server_principals AS sp ON dp.sid = sp.sid WHERE sp.sid IS NULL AND dp.authentication_type_desc = ''INSTANCE'' end;'
insert into #OrphanedUsers EXEC sp_MSforeachdb @command

select * from #OrphanedUsers