-- stored proc developed for DataSentinel is called up_PerformIndexOptimisationsUpTo100GB and is available in the DataAssure Snippets folder.

SET NOCOUNT ON;

DECLARE @DatabaseName SYSNAME;
DECLARE @SchemaName sysname
DECLARE @TableName sysname
DECLARE @IndexName sysname;
DECLARE @SQL NVARCHAR(MAX);
DECLARE @FillFactor int = 90
DECLARE @RebuildThreshold int = 30

-- IMPORTANT: If there is an index larger than 100GB it will not be included in the results. 
-- Make sure to adjust the @MaxPages variable to be greater than the largest index in your environment.
DECLARE @MaxPages bigint = 13107200; -- 13107200 pages/131072 = 100GB


-- Create a temporary table to store fragmentation results
create table #temp_indexes
(
    servername sql_variant,
    database_name nvarchar(255),
    schema_name nvarchar(255),
    table_name nvarchar(255),
    index_name nvarchar(255),
    index_type_desc nvarchar(60),
    avg_fragmentation_in_percent float,
    avg_fragment_size_in_pages float,
    page_count bigint,
    page_count_running_total_pages bigint NULL
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
    select serverproperty(''servername''), d.name databasename, sc.name schema_name, t.name tablename, i.name indexname, s.index_type_desc,
s.avg_fragmentation_in_percent, s.avg_fragment_size_in_pages, s.page_count, NULL AS page_count_running_total_pages
from sys.dm_db_index_physical_stats(DB_ID(),null,NULL,NULL,''LIMITED'') s
join sys.databases d on s.database_id = d.database_id
join sys.tables t on s.object_id = t.object_id
join sys.schemas sc on sc.schema_id = t.schema_id
join sys.indexes i on s.index_id = i.index_id
            and s.object_id = i.object_id
			and s.database_id = d.database_id
			where d.state = 0
            and s.page_count > 1000
            and  index_type_desc != ''HEAP''
            order by avg_fragmentation_in_percent desc';

    EXEC sp_executesql @SQL;

    FETCH NEXT FROM db_cursor INTO @DatabaseName;
END;

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- update the page_count_running_total_pages with a running total of page_count
;WITH x AS
(
    SELECT
        *,
        running_total_calc =
            SUM(page_count) OVER
            (
                ORDER BY
                    avg_fragmentation_in_percent DESC,
                    page_count DESC,
                    database_name,
                    schema_name,
                    table_name,
                    index_name
                ROWS UNBOUNDED PRECEDING
            )
    FROM #temp_indexes
)
UPDATE x
SET page_count_running_total_pages = running_total_calc;

-- Select the results from the temporary table under 100GB
DECLARE index_cursor CURSOR FOR
    SELECT
        database_name,
        schema_name,
        table_name,
        index_name
    FROM #temp_indexes
    WHERE page_count_running_total_pages <= @MaxPages
    and avg_fragmentation_in_percent >= @RebuildThreshold
    ORDER BY
        avg_fragmentation_in_percent DESC;

OPEN index_cursor;
FETCH NEXT FROM index_cursor INTO @DatabaseName, @SchemaName, @TableName, @IndexName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@DatabaseName) + '.' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' REBUILD WITH (FILLFACTOR = ' + CAST(@FillFactor as varchar(3)) + ');';
    select @SQL;
    FETCH NEXT FROM index_cursor INTO @DatabaseName, @SchemaName, @TableName, @IndexName;
END

CLOSE index_cursor;
DEALLOCATE index_cursor;

-- Clean up the temporary table
DROP TABLE #temp_indexes