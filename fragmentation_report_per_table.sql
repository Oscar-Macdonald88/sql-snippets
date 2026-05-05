USE dbame -- make sure to replate with the correct DB name
GO

drop table if exists #tsql

drop table if exists #Fragmentation

create table #tsql (sequno int, tsql nvarchar(max))

insert into #tsql select 1, 'CREATE TABLE #Fragmentation(
	[DatabaseName] [varchar](128) NOT NULL,
	[TableName] [varchar](128) NOT NULL,
	[IndexName] [varchar](100) NOT NULL,
	[FragPercent] [float] NOT NULL,
	[PageCount] [int] NOT NULL,
) ON [PRIMARY]'

insert into #tsql select 2, 'GO'

insert into #tsql select 3, 
'insert into #Fragmentation select d.name databasename, o.name tablename, i.name indexname,
avg_fragmentation_in_percent, page_count
from sys.dm_db_index_physical_stats(db_id(),object_id(''['+ s.name + '].[' + t.name+ ']''),NULL,NULL,''LIMITED'') s
join sys.databases d on s.database_id = d.database_id
join sys.objects o on s.object_id = o.object_id
join sys.indexes i on s.index_id = i.index_id
            and s.object_id = i.object_id
			and s.database_id = d.database_id
			where d.state = 0
            and page_count > 1000
            and  index_type_desc != ''HEAP'''
from sys.tables t
join sys.schemas s on s.schema_id = t.schema_id

insert into #tsql select 4, 'select * from #Fragmentation order by FragPercent desc'

select tsql from #tsql order by sequno