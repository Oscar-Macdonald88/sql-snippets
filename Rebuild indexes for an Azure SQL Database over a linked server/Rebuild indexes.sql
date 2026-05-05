SET NOCOUNT ON;


DECLARE 
      @RowID           INT
    , @DatabaseName    SYSNAME
    , @SchemaName      SYSNAME
    , @TableName       SYSNAME
    , @IndexName       SYSNAME
    , @sql             NVARCHAR(MAX)
    , @msg             NVARCHAR(4000);

-- Optional: only process rows that haven't been attempted or failed
-- You can change the WHERE clause to control scope (e.g., Success IS NULL or = 0)
DECLARE idx_cur CURSOR FAST_FORWARD FOR
SELECT RowID, DatabaseName, SchemaName, TableName, IndexName
FROM [Linked_Server].[Database_Name].[dbo].[dsl_index_optimisation]
ORDER BY RowID;

OPEN idx_cur;

FETCH NEXT FROM idx_cur INTO @RowID, @DatabaseName, @SchemaName, @TableName, @IndexName;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        -- Stamp StartDate
        UPDATE [Linked_Server].[Database_Name].[dbo].[dsl_index_optimisation]
        SET StartDate = SYSDATETIME()
        WHERE RowID = @RowID;

        SET @sql = N'
            ALTER INDEX ' + QUOTENAME(@IndexName) + N'
            ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + N'
            REBUILD WITH (
                  FILLFACTOR = 90
                , ONLINE = ON
                , SORT_IN_TEMPDB = ON
            );
        ';
        EXEC (@sql) AT [Linked_Server];

        -- Success
        UPDATE [Linked_Server].[Database_Name].[dbo].[dsl_index_optimisation]
        SET EndDate = SYSDATETIME(), Success = 1
        WHERE RowID = @RowID;
     
        SET @sql  = N'SET NOCOUNT ON;

        ;WITH file_usage AS
        (
            SELECT
                DB_NAME()                                 AS database_name,
                df.file_id,
                df.name                                   AS file_name,
                df.type_desc,
                df.physical_name,
                df.size                                   AS total_pages,
                FILEPROPERTY(df.name, ''SpaceUsed'')      AS used_pages,
                df.max_size,
                df.growth,
                df.is_percent_growth,
                df.state_desc
            FROM sys.database_files AS df
            WHERE df.type_desc = ''ROWS''
            AND df.state_desc = ''ONLINE''
        )
        , file_space AS
        (
            SELECT
                database_name,
                file_id,
                file_name,
                type_desc,
                physical_name,
                total_pages,
                used_pages,
                (total_pages - used_pages) AS free_pages
            FROM file_usage
        )
        UPDATE [dbo].[dsl_index_optimisation]
            SET [DBFreeSpaceMB] = (select SUM(free_pages) * 8 / 1024
        FROM file_space)
        WHERE RowID = ' + cast(@RowID as varchar(10)) + ';'
        EXEC (@sql) AT [Linked_Server];

    END TRY
    BEGIN CATCH
        -- Failure
        UPDATE [Linked_Server].[Database_Name].[dbo].[dsl_index_optimisation]
        SET EndDate = SYSDATETIME(), Success = 0
        WHERE RowID = @RowID;

        -- Optional: print/log error for visibility
        DECLARE @ErrMsg NVARCHAR(2048) = ERROR_MESSAGE();
        DECLARE @ErrNum INT = ERROR_NUMBER();
        DECLARE @ErrSev INT = ERROR_SEVERITY();
        DECLARE @ErrSta INT = ERROR_STATE();
        DECLARE @ErrLin INT = ERROR_LINE();
        RAISERROR(
            'Failed RowID=%d, [%s].[%s].[%s] -> [%s]. Error %d, Severity %d, State %d, Line %d: %s',
            10, 1, @RowID, @DatabaseName, @SchemaName, @TableName, @IndexName,
            @ErrNum, @ErrSev, @ErrSta, @ErrLin, @ErrMsg
        );
    END CATCH;

    FETCH NEXT FROM idx_cur INTO @RowID, @DatabaseName, @SchemaName, @TableName, @IndexName;
END

CLOSE idx_cur;
DEALLOCATE idx_cur;

SET NOCOUNT OFF;
