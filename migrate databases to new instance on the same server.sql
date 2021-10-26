use master
set nocount on
declare
    @NewDataPath varchar(255) = 'C:\SQLData',--'C:\SQLServer\2019\SQLData',
    @NewLogPath varchar(255) = 'C:\SQLLogs'--'C:\SQLServer\2019\SQLLogs'

declare
    @DBName varchar(255),
    @FullPath varchar(255),
    @FileName varchar(255),
    @SQLName varchar(255),
    @Type varchar(255),
    @TSQL nvarchar(2000),
    @CMD varchar(2000),
    @Online varchar(4000)
set @Online = ''
/*
select '''' + name + ''',' as 'DBName' from sys.databases
go
*/
select sdb.name as 'DBName', smf.name as 'SQLName', physical_name as 'FullPath', right(physical_name, charindex('\', reverse(physical_name)) - 1) as 'FileName', type_desc as 'Type', sdb.state_desc as 'State', 0 as 'Status' into #FilesToMove
from sys.master_files smf inner join sys.databases sdb on smf.database_id = sdb.database_id
where
------------------------------------------------------------------------------------------------
--                     INPUT LIST OF DATABSES TO MIGRATE HERE                                 --
------------------------------------------------------------------------------------------------
sdb.name in (
)
while exists(select * from #FilesToMove) begin
    set @DBName = (select top(1) DBName from #FilesToMove)
    set @Online = @Online + 'create database [' + @DBName + '] on'
    while exists(select * from #FilesToMove where DBName = @DBName and Status = 0) begin
        set @FullPath = (select top(1) FullPath from #FilesToMove where DBName = @DBName and Status = 0)
        set @Type = (select top(1) Type from #FilesToMove where DBName = @DBName and Status = 0)
        set @FileName = (select top(1) FileName from #FilesToMove where DBName = @DBName and Status = 0)
        set @SQLName = (select top(1) SQLName from #FilesToMove where DBName = @DBName and Status = 0)
        set @Online = @Online + '(filename = ''' + case when @Type = 'ROWS' then @NewDataPath else @NewLogPath end + '\' + @FileName + ''')'
        update top(1) #FilesToMove set Status = 1 where DBName = @DBName and Status = 0
        if exists(select * from #FilesToMove where DBName = @DBName and Status = 0) begin
            set @Online = @Online + ','
        end
    end
    set @Online = @Online + 'for attach' + CHAR(10)
    set @TSQL = 'USE [' + @DBName + '] alter database [' + @DBName + '] set offline with rollback immediate'
    if (select top(1) State from #FilesToMove) != 'OFFLINE' begin
        exec sp_executesql @TSQL
    end
    set @TSQL = 'EXEC sp_detach_db ''' + @DBName + ''', ''true'';  '
    exec sp_executesql @TSQL
    while exists(select * from #FilesToMove where DBName = @DBName) begin
        set @FullPath = (select top(1) FullPath from #FilesToMove where DBName = @DBName)
        set @Type = (select top(1) Type from #FilesToMove where DBName = @DBName)
        set @FileName = (select top(1) FileName from #FilesToMove where DBName = @DBName)
        if (@Type = 'ROWS' and @FullPath not like @NewDataPath + '%')
        or (@Type = 'LOG' and @FullPath not like @NewLogPath + '%') begin
            set @CMD = 'move ' + @FullPath + ' ' + case when @Type = 'ROWS' then @NewDataPath else @NewLogPath end + '\' + @FileName
            exec xp_cmdshell @CMD
        end
        delete top(1) from #FilesToMove where DBName = @DBName
    end
end
print @Online
drop table #FilesToMove