use EIT_DBA
create table #temp_indexes
(
    servername sql_variant,
    database_name nvarchar(255),
    table_name nvarchar(255),
    index_name nvarchar(255),
    index_type_desc nvarchar(60),
    avg_fragmentation_in_percent float,
    avg_fragment_size_in_pages float,
    page_count bigint
)

declare @sql nvarchar(max) 
set @sql = 'select serverproperty(''servername''), d.name databasename, o.name tablename, i.name indexname, index_type_desc,
avg_fragmentation_in_percent, avg_fragment_size_in_pages, page_count
from sys.dm_db_index_physical_stats(DB_ID(),null,NULL,NULL,''LIMITED'') s
join sys.databases d on s.database_id = d.database_id
join sys.objects o on s.object_id = o.object_id
join sys.indexes i on s.index_id = i.index_id
            and s.object_id = i.object_id
			and s.database_id = d.database_id
			where d.state = 0
            and page_count > 1000
            and  index_type_desc != ''HEAP''
            order by avg_fragmentation_in_percent desc'

insert into #temp_indexes exec EIT_DBA..dba_ForEachDB @sql
select * from #temp_indexes
drop table #temp_indexes