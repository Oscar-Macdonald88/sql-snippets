DECLARE @SSL_helpDB TABLE ([name] VARCHAR(200), [size] VARCHAR(20), [owner] VARCHAR(50), [dbid] INT, [created] DATETIME, [status] VARCHAR(4000), [compat] INT);
INSERT @SSL_helpDB EXEC sp_helpdb;

select distinct
h.name
, h.owner
, h.size as [Database Size]
, (select cast (o.size / 1000 as nvarchar(100)) + ' MB'where o.type_desc = 'ROWS' and d.database_id = o.database_id) as [Log Size MB]
, case o.max_size 
    when -1 then 'No Max Size' 
    else cast(o.max_size as nvarchar(100)) 
end as [Data Max Size]
, case o.is_percent_growth 
    when 1 then cast(o.growth as nvarchar(100)) + '%' 
    ELSE cast(o.growth / 1000 as nvarchar(100)) + ' MB' 
end as [Data Growth(Percent/Bytes)]
, h.status
from sys.databases d join sys.master_files o on d.database_id = o.database_id join @SSL_helpDB h on d.database_id = h.dbid
where o.type_desc = 'ROWS'
