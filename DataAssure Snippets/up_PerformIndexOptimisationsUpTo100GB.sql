create procedure dsl.up_PerformIndexOptimisationsUpTo100GB
as
begin
    set nocount on;
    declare @OptimiseStartTime datetime;
    declare @OptimiseEndTime datetime;
    declare @DatabaseName SYSNAME;
    declare @SchemaName sysname
    declare @TableName sysname
    declare @IndexName sysname;
    declare @SQL NVARCHAR(MAX);
    declare @FillFactor int = 90;
    declare @RebuildThreshold int = 30;
    declare @TimeLimitSeconds int;
    declare @TaskName varchar(30) = 'performindexoptimise'
    
    -- IMPORTANT: If there is an index larger than 100GB it will not be included in the results. 
    -- Make sure to adjust the @MaxPages variable to be greater than the largest index in your environment.
    declare @MaxPages bigint = 13107200; -- 13107200 pages/131072 = 100GB

    select @OptimiseStartTime = getdate();

    select @TimeLimitSeconds = TimeLimitSeconds
    from 
	    dsl.tbl_DBOptimiseConfig 
    where 
        [Databases] in ('SYSTEM_DATABASES','USER_DATABASES','ALL_DATABASES','AVAILABILITY_GROUP_DATABASES')
        and ExcludeFromMaintenance = 'N'

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
    declare db_cursor cursor for
    select name
    from sys.databases
    where database_id > 4 -- Exclude system databases (master, model, msdb, tempdb)
    and state = 0; -- Only online databases

    open db_cursor;
    fetch next from db_cursor into @DatabaseName;

    while @@FETCH_STATUS = 0
    begin
        set @SQL = 'USE ' + QUOTENAME(@DatabaseName) + ';
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

        exec sp_executesql @SQL;

        fetch next from db_cursor INTO @DatabaseName;
    end;

    close db_cursor;
    deallocate db_cursor;

    -- update the page_count_running_total_pages with a running total of page_count
    ;with x as
    (
        select
            *,
            running_total_calc =
                sum(page_count) over
                (
                    order by
                        avg_fragmentation_in_percent desc,
                        page_count desc,
                        database_name,
                        schema_name,
                        table_name,
                        index_name
                    rows unbounded preceding
                )
        from #temp_indexes
    )
    update x
    set page_count_running_total_pages = running_total_calc;


    -- Select the results from the temporary table under 100GB
    declare index_cursor cursor for
        select
            database_name,
            schema_name,
            table_name,
            index_name
        from #temp_indexes
        where page_count_running_total_pages <= @MaxPages
        and avg_fragmentation_in_percent >= @RebuildThreshold
        order by
            avg_fragmentation_in_percent desc;

    open index_cursor;
    fetch next from index_cursor into @DatabaseName, @SchemaName, @TableName, @IndexName;

    while @@FETCH_STATUS = 0
    begin
        set @SQL = quotename(@DatabaseName) + '.' + quotename(@SchemaName) + '.' + QuotenamE(@TableName) + '.' + quotename(@IndexName)
        exec [DBAToolset].[dbo].[IndexOptimize] 
            @Databases = @DatabaseName
            , @FragmentationLow = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'
            , @FragmentationMedium = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'
            , @FragmentationHigh  = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'
            , @SortInTempdb = 'Y'
            , @FillFactor = @FillFactor
            , @Indexes = @SQL;
        fetch next from index_cursor into @DatabaseName, @SchemaName, @TableName, @IndexName;
    end

    close index_cursor;
    deallocate index_cursor;

    -- clean up the temporary table
    drop table #temp_indexes

    	-- grab the end time so we can assess whether the process hit the time limit
	select @OptimiseEndTime = getdate()

	if datediff(second, @OptimiseStartTime, @OptimiseEndTime) >= @TimeLimitSeconds
	begin
		
			;with cte_timeLimitReached(TimeLimitData)
			as
			(	
				select 
					1 as LimitReached
					,@TimeLimitSeconds as TimeLimitSeconds
				for xml path('OptimiseTimeLimits'), root ('OptimiseTimeLimit'), elements XSINIL
			)
	
			insert into dsl.tbl_Message 
			select 
				@TaskName
				,TimeLimitData
				,getutcdate()
				,null
				,null
			from 
				cte_timeLimitReached

	end


	if exists (select * from dbo.CommandLog where CommandType = 'ALTER_INDEX' and StartTime > @OptimiseStartTime and ErrorNumber <> 0)
	begin
		-- log the issue

		;with cte_OptimiseError(ErrorData)
		as
		(
			select
				@DatabaseName as CommandGroup
				,DatabaseName
				,StartTime
				,EndTime
				,ErrorNumber
			from
				dbo.CommandLog 
			where 
				CommandType = 'ALTER_INDEX' 
				and StartTime > @OptimiseStartTime 
				and ErrorNumber <> 0
			for xml path('OptimiseErrors'), root('OptimiseError'), elements XSINIL
		)
		
		insert into dsl.tbl_Message
		select
			@TaskName
			,ErrorData
			,getutcdate()
			,null
			,null
		from
			cte_OptimiseError

		return

	end
	else -- no errors, but return the notification
	begin
		if exists (select * from dbo.CommandLog where CommandType = 'ALTER_INDEX' and StartTime > @OptimiseStartTime)
		begin
			;with cte_OptimiseSuccess(SuccessData)
			as
			(
				select
					@DatabaseName as CommandGroup
					,DatabaseName
					,StartTime
					,EndTime
				from
					dbo.CommandLog 
				where 
					CommandType = 'ALTER_INDEX' 
					and StartTime > @OptimiseStartTime 
				for xml path('OptimiseSuccesses'), root('OptimiseSuccess'), elements XSINIL		
			)
		
			insert into dsl.tbl_Message
			select
				@TaskName
				,SuccessData
				,getutcdate()
				,null
				,null
			from
				cte_OptimiseSuccess
		end
	end

	-- and then clean up any backup information logged older than 30 days
	delete dbo.CommandLog where EndTime < dateadd(day, -30, getdate())
end