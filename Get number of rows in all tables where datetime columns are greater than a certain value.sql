-- A client had an issue where they had a 'time slip' and they suspected that some rows were added\updated with date times in the future
-- This script generates another script that reports which datetime columns in each table have rows between two dates.

-- Make sure you are running in the desired database
-- USE DatabaseName

-- Variables
declare @startDate datetime = '2025-10-03 23:59'
declare @endDate datetime = '2025-10-05 00:00'

create table #tempSQL (
    ID INT IDENTITY(1,1),
    [T-SQL] nvarchar(max)
)

insert into #tempSQL select ('create table #tempdatecheck (DatabaseName nvarchar(255), TableName nvarchar(255), ColumnName nvarchar(255), [NumberOfEntriesBetweenTheTwoDates] int)')

insert into #tempSQL select ('if exists (select top 1 1 from [' +db_name() + '].[' +SCHEMA_NAME(t.schema_id) + '].[' + t.name + '] where [' + c.name + ']  between ''' + cast(@startDate as VARCHAR(20)) + ''' and ''' + cast(@endDate as VARCHAR(20)) + ''') begin; insert into #tempdatecheck select top 1 ''' + db_name() + ''' as [DatabaseName], ''' + t.name + ''' as [TableName], ''' + c.name + ''' as [ColumnName], count(*) as [NumberOfEntriesBetween ' + cast(@startDate as VARCHAR(20)) + ' and ' + cast(@endDate as VARCHAR(20)) + '] from [' + db_name() + '].[' + SCHEMA_NAME(t.schema_id) + '].[' + t.name + '] where [' + c.name + '] between ''' + cast(@startDate as VARCHAR(20)) + ''' and ''' + cast(@endDate as VARCHAR(20)) + '''; end;')
FROM 
    sys.columns c
INNER JOIN 
    sys.tables t ON c.object_id = t.object_id
WHERE 
    TYPE_NAME(c.user_type_id) IN ('date', 'datetime', 'datetime2', 'smalldatetime', 'datetimeoffset', 'time')
ORDER BY t.name, c.name

insert into #tempSQL select ('select * from #tempdatecheck;')
insert into #tempSQL select ('drop table #tempdatecheck;')

select [T-SQL] from #tempSQL order by ID;

drop table #tempSQL