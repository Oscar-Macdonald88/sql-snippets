-- This script is designed to be run as a SQL Agent job, and will alert if any of the Availability Groups are not healthy.

if exists(select 1 FROM [EIT_DBA].[dbo].[AvailabilityGroupStatistics]
	where PrimarySynchronizationHealthDesc <> 'HEALTHY'
	or ConnectedStateDesc <> 'CONNECTED'
	or SecondaryStateDesc <> 'CONNECTED'
	or SynchronizationHealthDesc <> 'HEALTHY'
)
begin
	IF NOT EXISTS(SELECT 1 FROM EIT_DBA.alert.[BrownOut] WHERE GETDATE() BETWEEN StartsAt AND EndsAt) /* No brownout in place */
	AND EXISTS (
		/* Is this at a time we should page at for this server? */
		SELECT 1
		FROM
			EIT_DBA.alert.PagingTimes
		WHERE
			[Weekday] = DATEPART(WEEKDAY, GETDATE())
		AND DATEPART(HOUR, GETDATE()) * 10000 + DATEPART(MINUTE, GETDATE()) * 100 + DATEPART(SECOND, GETDATE()) BETWEEN StartTime AND EndTime
		)
	BEGIN

		DECLARE @dba_cust               NVARCHAR(128);
		DECLARE @dba_email_opr          NVARCHAR(MAX);
		DECLARE @dba_page_opr           NVARCHAR(MAX);
		DECLARE @additional_page_opr    NVARCHAR(MAX) = 'All-FNL-Card-ITOPS@sbs.net.nz';
		DECLARE @custom_subj            NVARCHAR(max);
		DECLARE @custom_page_subj       NVARCHAR(max);
		DECLARE @dba_query_clmns		NVARCHAR(max);
		DECLARE @dba_query_data_clmns	NVARCHAR(max);
		DECLARE @dba_query_tbl_html_build nvarchar(max);
		DECLARE @custom_body            NVARCHAR(max);
		DECLARE @importance				NVARCHAR(6) = 'High';
		DECLARE @dba_cust_is_24h        CHAR(1);
		DECLARE @send_page              CHAR(1) = 'n';--Flag to determine if pages should be sent
    
		SET @dba_cust = EIT_DBA.dbo.ConfigValueGet('customer_code');
		SET @custom_subj = @dba_cust + ' - Event(Critical) - ' + CONVERT(NVARCHAR, SERVERPROPERTY('servername')) + ' - Availability Group is not healthy';
		set @custom_page_subj = @dba_cust + ' - Page(Critical) - ' + CONVERT(NVARCHAR, SERVERPROPERTY('servername')) + ' - Availability Group is not healthy';
		SET @dba_cust_is_24h = EIT_DBA.dbo.ConfigValueGet('24x7_customer');
		SET @dba_email_opr = EIT_DBA.dbo.ConfigValueGet('alert_email');

		SELECT @dba_query_clmns = COALESCE(@dba_query_clmns, '') + '<th>' + COLUMN_NAME + '</th>'
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE 1 = 1
			AND TABLE_NAME = N'AvailabilityGroupStatistics'
			AND COLUMN_NAME IN ( 'AvailabilityGroupName', 'PrimarySQLInstance', 'PrimarySynchronizationHealthDesc', 'ConnectedStateDesc', 'SecondaryStateDesc', 'SecondarySQLInstance','SynchronizationHealthDesc' )
		ORDER BY ORDINAL_POSITION;

		SET @dba_query_data_clmns = NULL;

		SELECT @dba_query_data_clmns = COALESCE(@dba_query_data_clmns + ',', '') + COLUMN_NAME + ' AS td,'''''
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE 1 = 1
			AND TABLE_NAME = N'AvailabilityGroupStatistics'
			AND COLUMN_NAME IN ( 'AvailabilityGroupName', 'PrimarySQLInstance', 'PrimarySynchronizationHealthDesc', 'ConnectedStateDesc', 'SecondaryStateDesc', 'SecondarySQLInstance','SynchronizationHealthDesc' )
		ORDER BY ORDINAL_POSITION;
        
		SET @dba_query_tbl_html_build = 'SELECT ''<b>Date:</b> ' + CONVERT(VARCHAR, GETDATE(), 103) + '<b> Time: </b>' + CONVERT(VARCHAR, GETDATE(), 108) + '<br>'
		+ '<br><br><table border="1"><tr>' + @dba_query_clmns + '</tr>'' + CAST ( (
		SELECT TOP 1 ' + @dba_query_data_clmns + '
		FROM AvailabilityGroupStatistics
		where PrimarySynchronizationHealthDesc <> ''HEALTHY''
		or ConnectedStateDesc <> ''CONNECTED''
		or SecondaryStateDesc <> ''CONNECTED''
		or SynchronizationHealthDesc <> ''HEALTHY''
		FOR XML PATH(''tr'')
		) AS nvarchar(max))
		+ N''</table>''';

		-- create table variable to hold output
		DECLARE @dba_query_rslt_tmp_tbl TABLE (c1 NVARCHAR(max));

		-- insert html into table variable 
		INSERT INTO @dba_query_rslt_tmp_tbl
		EXECUTE (@dba_query_tbl_html_build);

		SET @custom_body = (SELECT c1 FROM @dba_query_rslt_tmp_tbl);

		IF (@dba_cust_is_24h = 'y') -- pageable
		BEGIN
			SET @send_page = 'y';
			SET @dba_page_opr = ISNULL(EIT_DBA.dbo.ConfigValueGet('alert_page'),@dba_email_opr) + ';' + @additional_page_opr; -- If alert_page is not set, fall back to alert email.
		END;

		--Send page
		if (@send_page = 'y')
		EXECUTE EIT_DBA.dbo.usp_eit_send_alert
			@page_out            = @send_page
			,@dba_cust            = @dba_cust
			,@dba_email_opr        = @dba_email_opr
			,@dba_page_opr        = @dba_page_opr
			,@email_subj        = @custom_subj
			,@email_body        = @custom_body
			,@page_subj            = @custom_page_subj
			,@page_body            = @custom_body
			,@importance        = @importance;

		--Send email
		EXECUTE EIT_DBA.dbo.usp_eit_send_alert
			@page_out            = 'n'
			,@dba_cust            = @dba_cust
			,@dba_email_opr        = @dba_email_opr
			,@dba_page_opr        = @dba_page_opr
			,@email_subj        = @custom_subj
			,@email_body        = @custom_body
			,@page_subj            = @custom_page_subj
			,@page_body            = @custom_body
			,@importance        = @importance;
	end
end

