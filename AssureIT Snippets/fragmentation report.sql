SET NOCOUNT ON;

DECLARE @DatabaseName SYSNAME;
DECLARE @SQL NVARCHAR(MAX);

-- Create a temporary table to store fragmentation results
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

-- Declare a cursor to iterate through user databases
DECLARE db_cursor CURSOR FOR
SELECT name
FROM sys.databases
WHERE database_id > 4 -- Exclude system databases (master, model, msdb, tempdb)
AND state = 0; -- Only online databases

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @DatabaseName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'USE ' + QUOTENAME(@DatabaseName) + ';
    INSERT INTO #temp_indexes
    select serverproperty(''servername''), d.name databasename, o.name tablename, i.name indexname, index_type_desc,
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
            order by avg_fragmentation_in_percent desc';

    EXEC sp_executesql @SQL;

    FETCH NEXT FROM db_cursor INTO @DatabaseName;
END;

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- Select the results from the temporary table
SELECT *
FROM #temp_indexes
ORDER BY database_name, table_name, avg_fragmentation_in_percent DESC;

-- Clean up the temporary table
DROP TABLE #temp_indexes