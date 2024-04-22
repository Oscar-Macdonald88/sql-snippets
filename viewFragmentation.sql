-- use dbname
select o.name, i.name, index_type_desc,
index_depth, index_level, avg_fragmentation_in_percent,
fragment_count, avg_fragment_size_in_pages, page_count,record_count
from sys.dm_db_index_physical_stats(db_ID(),null,NULL,NULL,'LIMITED') s
join sys.objects o on s.object_id = o.object_id
join sys.indexes i on s.index_id = i.index_id
            and s.object_id = i.object_id
            where page_count > 1000
            and  index_type_desc != 'HEAP'
--          and o.name = 'ACCOUNTINGDISTRIBUTION'
            order by   avg_fragmentation_in_percent desc 
