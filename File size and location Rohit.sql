IF exists (
    select
        name
    from
        tempdb..sysobjects
    where
        name like '#datafilesize%'
) BEGIN Drop table #datafilesize;
END create table #datafilesize
(
    database_name varchar(180),
    name varchar(180),
    physical_name varchar(max),
    recovery_Model nvarchar(15),
    currentsizeMB varchar(50),
    AvailableSpaceInMB float(50),
    Last_backup_date nvarchar(100)
)
Insert Into
    #datafilesize
    EXEC sp_msforeachdb 'use [?];
select DB_NAME(dbid),a.name, filename,b.recovery_model_desc,(size*8)/1024 as CurentsizeinMB,
((size*8)/1024) - (CAST(FILEPROPERTY(a.name, ''SpaceUsed'') AS int)/128) AS AvailableSpaceInMB,
CASE WHEN filename like ''%.ldf'' and b.recovery_model_desc IN (''FULL'',''BULK_LOGGED'')
THEN cast (max(c.backup_start_date) as nvarchar) ELSE
CASE WHEN b.recovery_model_desc = ''SIMPLE'' and filename like ''%.ldf''
THEN ''Last Full Backup: '' + cast (max(c.backup_start_date) as nvarchar)
ELSE ''This is Data File''
END
END as Last_backup_date
from sys.sysaltfiles a
INNER JOIN sys.databases b
ON
a.dbid = b.database_id
INNER JOIN msdb.dbo.backupset c
ON
DB_NAME(b.database_id) = c.database_name
AND
DB_NAME(dbid) = DB_NAME(db_id())
group by a.dbid, a.filename,b.recovery_model_desc,a.name,a.size' IF exists (
        select
            name
        from
            tempdb..sysobjects
        where
            name like '#diskspace%'
    ) BEGIN Drop table #diskspace;
END create table #diskspace
(Drive nvarchar(5), Space_free nvarchar(20))
insert into
    #diskspace
    EXEC xp_fixeddrives;

select
    database_name,
    name,
CASE
        WHEN physical_name like '%.ldf' THEN 'Log File'
        ELSE 'Data File'
    END as Which_File,
    recovery_Model,
    physical_name,
    currentsizeMB,
    AvailableSpaceInMB,
    substring(physical_name, 1, 1) + ' ' + '\' + ' ' +
cast((b.Space_free/1024) as varchar(20)) + ' GB ' as ' Drive \ Free_Space ',Last_backup_date,
CASE
WHEN CAST(currentsizeMB - AvailableSpaceInMB as nvarchar) > 1000
THEN ' Use ' +' [' + database_name + '];

' + CHAR(13) + ' DBCC shrinkfile (
    ' + '''' + name + '''' + ',
    ' + ((CAST(currentsizeMB - AvailableSpaceInMB + 1024 as nvarchar))) + ' * ' + '
) ' + ';

'
WHEN CAST(currentsizeMB - AvailableSpaceInMB as nvarchar) < 1000
THEN ' Use ' +' [' + database_name + '];

' + CHAR(13) + ' DBCC shrinkfile (
    ' + '''' + name + '''' + ',
    ' + ((CAST(currentsizeMB - AvailableSpaceInMB + 256 as nvarchar))) + ' * ' + '
) ' + ';

'
WHEN physical_name LIKE ' %.ldf '
THEN ' Use ' +' [' + database_name + '];

' + CHAR(13) + ' DBCC shrinkfile (
    ' + '''' + name + '''' + ',
    ' + ((CAST(currentsizeMB - AvailableSpaceInMB as nvarchar))) + ' * ' + '
) ' + ';

'
END
as Sample_script_to_shrink_file
from #datafilesize a,#diskspace b
where
substring(a.physical_name,1,1) = b.Drive
order by availablespaceinMB desc;
drop table #datafilesize;
drop table #diskspace;