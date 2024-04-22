declare @command varchar(255)

drop table if exists #FileSizes

-- alternative for versions before 2016
--IF OBJECT_ID('tempdb..#FileSizes') IS NOT NULL DROP TABLE #FileSizes

create TABLE #FileSizes (
dbname nvarchar(255),
filename nvarchar(255),
filetype nvarchar(255),
Size_MBs bigint,
Size_GBs bigint
)

select @command = 'use [?] SELECT db_name(), ROUNDCAST(size as bigint) * 8 / 1024, 0) as Size_MBs, (cast(size AS bigint) * 8 / 1024) / 1024 AS size_GBs from sys.database_files'

insert into #FileSizes exec sp_msforeachdb @command

select * from #FileSizes where dbname not in ('master','model','msdb','tempdb','EIT_DBA') order by dbname