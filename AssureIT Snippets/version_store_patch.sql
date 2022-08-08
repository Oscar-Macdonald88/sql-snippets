USE [EIT_DBA];
GO
DROP TABLE [dbo].[EIT_stage_alert_version_store_usage];
GO
CREATE TABLE [dbo].[EIT_stage_alert_version_store_usage](
    [version_store_size_mb] [numeric](12, 2) NULL,
    [tempdb_data_size_mb] [numeric](12, 2) NULL,
    [percentage] [numeric](5, 2) NULL
) ON [PRIMARY];
GO
ALTER PROCEDURE [dbo].[usp_eit_alert_version_store_usage]
AS
BEGIN;
    SET NOCOUNT ON;

    IF (DATEPART(MINUTE,GETDATE()) = 0) -- Run every 1 hr.
    BEGIN

        DECLARE @is_enabled             CHAR(1);
        DECLARE @alert_priority_desc    NVARCHAR(50);
        DECLARE @event_name             NVARCHAR(50);
        DECLARE @email_event            CHAR(1);
        DECLARE @page_event             CHAR(1);
        DECLARE @percentage_threshold   NUMERIC(5, 2);
        DECLARE @sqlcmd                 NVARCHAR(MAX);
        DECLARE @dba_query_wExclusions  NVARCHAR(MAX);

        SET @event_name = 'VERSION_STORE_USAGE';

        SELECT @is_enabled = is_enabled, @email_event = e.email_event, @page_event = e.page_event, @alert_priority_desc = a.alert_priority_desc, @percentage_threshold = CAST(COALESCE([email_event_threshold],'30.0') AS NUMERIC(5,2))
        FROM [dbo].[EIT_monitoring_config_event] e
        JOIN [dbo].[EIT_monitoring_alert_priority] a
        ON e.alert_priority_id = a.alert_priority_id
        WHERE e.event_name = @event_name;

        IF (@is_enabled = 'n' OR (@email_event = 'n' AND @page_event = 'n'))
        BEGIN
            RETURN;
        END;

        TRUNCATE TABLE dbo.EIT_stage_alert_version_store_usage;

        -- TODO
        -- Create sqlcmd to get size of version store compared to size of tempdb.
        SELECT @sqlcmd = '
        with results as (
            select
                SUM(v.version_store_reserved_page_count) / 128.00 as version_store_mb,
                sum(t.size) / 128.00 as tempdb_data_size_mb,
                (
                    SUM (v.version_store_reserved_page_count) * 1.00 / sum(t.size) * 1.00
                ) * 100.00 as version_store_percentage
           from
                tempdb.sys.database_files as t
                join tempdb.sys.dm_db_file_space_usage as v
			    on t.file_id = v.file_id
            where
                t.type = 0
        )
        select
            version_store_mb,
            tempdb_data_size_mb,
            version_store_percentage
        from
            results
        where
            version_store_percentage > ' + cast(@percentage_threshold as varchar(6));

        EXEC dbo.usp_eit_monitoring_build_event_exclusions
                @exclusion_code = @event_name
                ,@query         = @sqlcmd
                ,@results       = @dba_query_wExclusions OUTPUT;

        INSERT INTO dbo.EIT_stage_alert_version_store_usage
        EXEC sp_executesql @stmt = @dba_query_wExclusions;

        -- if the table is NOT empty, generate an alert i.e., the size of version store has exceeded the threshold
        IF EXISTS (SELECT 1 FROM dbo.EIT_stage_alert_version_store_usage)
        BEGIN
            -- generate header
            DECLARE @dba_query_clmns NVARCHAR(max)

            SELECT @dba_query_clmns = COALESCE(@dba_query_clmns, '') + '<th>' + COLUMN_NAME + '</th>'
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE 1 = 1
                AND TABLE_NAME = N'EIT_stage_alert_version_store_usage'
            ORDER BY ORDINAL_POSITION

            -- generate body
            DECLARE @dba_query_data_clmns NVARCHAR(max)

            SELECT @dba_query_data_clmns = COALESCE(@dba_query_data_clmns + ',', '') + COLUMN_NAME + ' AS td,'''''
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE 1 = 1
                AND TABLE_NAME = N'EIT_stage_alert_version_store_usage'
            ORDER BY ORDINAL_POSITION

            -- create html 
            DECLARE @dba_query_tbl_html_build NVARCHAR(max)
    
            SET @dba_query_tbl_html_build = N'SELECT ''<b>Date:</b> ' + CONVERT(VARCHAR, GETDATE(), 103) + N'<b> Time: </b>' + CONVERT(VARCHAR, GETDATE(), 108) + N'<br><b>Version Store Percent Threshold:</b> When the version store reaches a certain percentage use of tempdb<br><i>(Exclusion code: ' + @event_name + ', column_name: percentage, exclusion: 0)</i><br><br>''
            +''<table border="1"><tr>' + @dba_query_clmns + N'</tr>'' + CAST ( (
            SELECT ' + @dba_query_data_clmns + N'
            FROM EIT_stage_alert_version_store_usage 
            FOR XML PATH(''tr'')
            ) AS nvarchar(max))
            + ''</table>'''

            -- create table variable to hold output
            DECLARE @dba_query_rslt_tmp_tbl TABLE (c1 NVARCHAR(max))

            -- insert html into table variable 
            INSERT INTO @dba_query_rslt_tmp_tbl
            EXECUTE (@dba_query_tbl_html_build)

            DECLARE @dba_email_subj NVARCHAR(max)

            SET @dba_email_subj = dbo.FormatSubject('Event', @alert_priority_desc, 'Version Store Percent Threshold')

            DECLARE @dba_email_body NVARCHAR(max)

            SET @dba_email_body = (
                    SELECT c1
                    FROM @dba_query_rslt_tmp_tbl
                    )

            -- Send alert
            IF (@email_event = 'y')
            BEGIN
                EXECUTE [dbo].[usp_eit_alert] 
                    @custom_page        = 'n'
                    ,@custom_subj       = @dba_email_subj
                    ,@custom_page_subj  = NULL
                    ,@custom_body       = @dba_email_body
                    ,@category          = 'version_store_usage'
                    ,@importance        = 'High';
            END;

            IF (@page_event = 'y')
            BEGIN
                DECLARE @dba_page_subj nvarchar(max);

                SET @dba_page_subj = dbo.FormatSubject('Page', @alert_priority_desc, 'Version Store Percent Threshold')

                EXECUTE [dbo].[usp_eit_alert] 
                @custom_page        = 'y'
                ,@custom_subj       = NULL
                ,@custom_page_subj  = @dba_page_subj
                ,@custom_body       = NULL
                ,@category          = 'version_store_usage';
            END;
    
        END;
    END;
END;
GO
