select serverproperty('servername'), d.name databasename, o.name tablename, i.name indexname, index_type_desc,
avg_fragmentation_in_percent, avg_fragment_size_in_pages, page_count
from sys.dm_db_index_physical_stats(null,null,NULL,NULL,'LIMITED') s
join sys.databases d on s.database_id = d.database_id
join sys.objects o on s.object_id = o.object_id
join sys.indexes i on s.index_id = i.index_id
            and s.object_id = i.object_id
			and s.database_id = d.database_id
			where d.state = 0
            and page_count > 1000
			--and fragment_count > 50
            and  index_type_desc != 'HEAP'
            order by   avg_fragmentation_in_percent desc