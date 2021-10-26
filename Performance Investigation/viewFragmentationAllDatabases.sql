Declare @Fragmentation table (DBName varchar(128), TableName varchar(128), IndexName varchar (100), FragPercent float, pageCount int);

Insert into @Fragmentation
exec SP_MSforeachdb @command1 = 
            'use [?];
                select DB_NAME() as [Database Name], o.name as [Table Name], i.name as [Index Name], avg_fragmentation_in_percent as [Fragmentation Percentage],
page_count as [Page Count]
from sys.dm_db_index_physical_stats(db_ID(),null,NULL,NULL,''LIMITED'') s
join sys.objects o on s.object_id = o.object_id
join sys.indexes i on s.index_id = i.index_id
            and s.object_id = i.object_id
            where page_count > 1000
            and  index_type_desc != ''HEAP''
            order by avg_fragmentation_in_percent desc '
select * from @Fragmentation
go