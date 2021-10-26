if exists (select 1 from sys.objects where name = 'up_CheckBlocking_custom' and type = 'P')
	drop procedure dbo.up_CheckBlocking_custom;
go

print 'Creating dbo.up_CheckBlocking_custom...';
go

create procedure dbo.up_CheckBlocking_custom 
(
	@ReportOnly bit = 0
)
with encryption
as
/*
	
	This procedure checks for blocking processes and alerts on them.  The alerting is based in a configurable threshold. 
	It keeps track of the head of the chain blocking SPIDs and alerts when these are no longer blocking.

	Using the @ReportOnly allows a quick report of the current blocking without invoking any alertion.

	History
	
	Date		Person	Comment
	----------	------	---------------------------------------------------------------------------------
	23-07-2015	Dean M	Created
	26-04-2016	Dean M	Updated with additional requirement to not send a "blocking" email when some blocking is cleared and there is still blocking
	12-05-2016	Dean M	Add another alert type to allow the recipient to distinquish between all blocking cleared and blocking changed
	06-04-2017	Hussain	Revised the code to fix all issues, and comply with the process flow in the requirements document @ 
						http://sslsp01/sites/development/Requirements/Template%20Check%20Blocking%20Requirements.docx 
	12-Jun-2017	Hussain	Fixed the issues reported in Share Point @
						http://sslsp01/sites/development/_layouts/15/listform.aspx?PageType=4&ListId=%7B86C7989C%2D72CF%2D48EE%2DB9F4%2D51961321422C%7D&ID=52&ContentTypeID=0x010009C276A2C033AF449B2A918B314AB2AA
						
*/
begin

	set nocount on;


	-- Declare variables
	declare @ServerName varchar(255)
		, @ThresholdMins int
		, @Message varchar(max)
		, @Class as varchar(15)
		, @SPID int
		, @BlockingChain nvarchar(2000)
		, @LoginName nvarchar(128)
		, @DurationMins int
		, @HostName nvarchar(128)
		, @ProgramName nvarchar(128)
		, @DatabaseName nvarchar(128)
		, @SqlStatement nvarchar(250);

	-- Initialize variables
	select @ServerName = cast(serverproperty('ServerName') as varchar)
		, @ThresholdMins =1; --isnull(dbo.GetParamInt('BlockingThresholdMins'), 60); -- default to 60 minutes

	-- Declare table variables
	declare @BlockingChains table
	(
		blocking_spid smallint
		, blocked_spid smallint
		, host_name nvarchar(128)
		, login_name nvarchar(128)
		, program_name nvarchar(128)
		, database_name nvarchar(128)
		, sql_statement nvarchar(max)
		, start_time datetime
		, blocked_spids varchar(255)
		, blocking_chain nvarchar(128)
	)

	declare @TempBlockingChains table
	(
		blocking_spid smallint
		, blocked_spid smallint
		, host_name nvarchar(128)
		, login_name nvarchar(128)
		, program_name nvarchar(128)
		, database_name nvarchar(128)
		, sql_statement nvarchar(max)
		, start_time datetime
		, blocked_spids varchar(255)
	)
	
	declare @BlockingSPIDs table
	(
		blocking_spid smallint
	)
	
	-- Retrieve all the blocking chains - including both the head of chain sessions and their blocked sessions
	insert into @TempBlockingChains
	select isnull(er.blocking_session_id, 0)
		, es.session_id
		, es.[host_name]
		, es.original_login_name
		, es.[program_name]
		, db_name(er.database_id)
		, substring
		  (
			est.text
			, (er.statement_start_offset / 2) + 1
			, (abs(case er.statement_end_offset when -1 then datalength(est.text) else er.statement_end_offset end - er.statement_start_offset)/2) + 1
		  )
		, er.start_time
		, null
	from sys.dm_exec_sessions es 
		left outer join sys.dm_exec_requests er on es.session_id = er.session_id
		outer apply sys.dm_exec_sql_text(er.sql_handle) as est
	where es.is_user_process = 1		-- Ignore system processes
		and es.session_id <> @@spid;  -- Ignore session id of the current user process

	with cte as
	(
		select blocked_spid as blocking_head_spid
			, blocked_spid
			, blocking_spid
			, host_name
			, login_name
			, program_name
			, database_name
			, sql_statement
			, start_time
			, blocked_spids
			, 0 as nestlevel
			, cast(blocked_spid as varchar(max)) as blocking_chain
		from @TempBlockingChains
		where blocking_spid = 0

		union all

		select cte.blocking_head_spid
			, tbc.blocked_spid
			, tbc.blocking_spid
			, tbc.host_name
			, tbc.login_name
			, tbc.program_name
			, tbc.database_name
			, tbc.sql_statement
			, tbc.start_time
			, tbc.blocked_spids
			, cte.nestlevel + 1
			, blocking_chain + ' <-- ' + cast(tbc.blocked_spid as varchar(max))
		from @TempBlockingChains tbc
			inner join cte on cte.blocked_spid = tbc.blocking_spid
	)
	, cte2 as 
	(
		select blocking_head_spid
			, blocked_spid
			, blocking_spid
			, host_name
			, login_name
			, program_name
			, database_name
			, sql_statement
			, start_time
			, blocked_spids
			, blocking_chain
		from cte
		where blocking_spid = 0
			and exists 
			(
				select 1 
				from cte cte2		-- This is called Recurrsion
				where cte2.blocking_spid = cte.blocked_spid
			)

		union all

		select blocking_head_spid
			, blocked_spid
			, blocking_spid
			, host_name
			, login_name
			, program_name
			, database_name
			, sql_statement
			, start_time
			, blocked_spids
			, blocking_chain
		from cte
		where blocking_spid <> 0
	)
	insert into @BlockingChains 
	select blocking_head_spid
		, blocked_spid
		, host_name
		, login_name
		, case left(program_name, 29)
			when 'SQLAgent - TSQL JobStep (Job ' then 'SQLAgent Job: ' 
				+ (select top 1 name from msdb..sysjobs sj where substring(program_name, 32, 32) = (substring(sys.fn_varbintohexstr(sj.job_id), 3, 100))) 
				+ ' - ' + substring(program_name, 67, abs(len(program_name) - 67))
			else program_name
		  end
		, database_name
		, sql_statement
		, start_time
		, blocked_spids
		, blocking_chain
	from cte2
	order by blocking_head_spid
		, blocking_chain;

	if @ReportOnly = 1 
	begin
		select blocking_spid
			, blocked_spid
			, blocking_chain
			, host_name
			, login_name
			, program_name
			, database_name
			, sql_statement
			, datediff(minute, start_time, getdate()) as [Duration(mins)]
		from @BlockingChains b;
		return;
	end

	-- Update the BlockingSPIDs field in @BlockingChains for each head of blocking chain
	declare @BlockingSPID int
		, @BlockedSPIDs varchar(255);
	-- Define cursor to loop through SPIDs of head of blocking chains
	declare cur_BlockingSPIDs cursor for
	select blocking_spid from @BlockingChains
	where blocking_spid = blocked_spid
	-- Open the cursor
	open cur_BlockingSPIDs;
	-- Fetch the SPID of first head of blocking chain
	fetch cur_BlockingSPIDs
	into @BlockingSPID
	-- Loop through SPIDs of head of blocking chains
	while (@@fetch_status = 0)
	begin
		set @BlockedSPIDs = null;
		-- Create a comma-separated list of SPIDs blocked by the head of blocking chain SPID
		select @BlockedSPIDs = coalesce(@BlockedSPIDs + ',', '') + convert(varchar, blocked_spid) 
		from @BlockingChains 
		where blocking_spid = @BlockingSPID 
			and blocked_spid <> @BlockingSPID;
		-- Update the head of blocking chain with the comma-separated list of blocked SPIDs
		update @BlockingChains 
		set blocked_spids = @BlockedSPIDs
		where blocked_spid = @BlockingSPID;
		-- Fetch the SPID for the next head of blocking chain
		fetch cur_BlockingSPIDs
		into @BlockingSPID
	end
	-- Close and deallocate the cursor
	close cur_BlockingSPIDs;
	deallocate cur_BlockingSPIDs;
	
	/*--------------------------------------------------------------------------------------------
	* Process flow step: Blocking chains found?
	* If yes, then:
	* - Take the snap shot of the current processes
	* - Send the blocking report, if BlockingAlertReportAvailable is set to 1 in tbl_Param
	*-------------------------------------------------------------------------------------------*/
	if exists
	(
		select 1
		from @BlockingChains
	)
	begin
		exec up_CaptureProcesses;
		if(dbo.GetParamInt('BlockingAlertReportAvailable') = 1)
			exec up_BlockingAlertReportZip
	end
	
	/*--------------------------------------------------------------------------------------------
	* Process flow step: New head of chain(s) found with breached threshold?
	* If yes, then send Alert_SSL_Blocking alert
	*-------------------------------------------------------------------------------------------*/
	insert into @BlockingSPIDs 
	select blocking_spid
	from @BlockingChains
	where blocking_spid = blocked_spid 
		and datediff(minute, start_time, getdate()) > @ThresholdMins/2
		and not exists 
		(
			select 1 
			from tbl_BlockingSPIDs 
			where EndDate is null
				and 
				(
					BlockingSPID = blocking_spid
					or
					(
						BlockingSPID <> blocking_spid
						and 
						(
							BlockedSPIDs = cast(blocking_spid as varchar)
								or BlockedSPIDs like cast(blocking_spid as varchar) + ',%'
								or BlockedSPIDs like '%,' + cast(blocking_spid as varchar)
								or BlockedSPIDs like '%,' + cast(blocking_spid as varchar) + ',%'
						)
					)
				)
		)
	
	if exists
	(
		select 1
		from @BlockingSPIDs
	)
	begin
		-- Compose the message body
		set @Message = '<html><head><style>.smallText {font-size:10pt;font-family:Arial} .even {background-color:#C0C0C0} .odd {background-color:#DCDCDC} '
			+ '.center {text-align:center} table {table-layout:fixed;width:1210px} table td {word-wrap:break-word;vertical-align:top} .footnote '
			+ '{font-size:9pt;color:#FF0000}</style></head><body class="smallText"><p>A SQL Server session ID (SPID) running on ' +  @ServerName + ' has been '
			+ 'identified as blocking other SPIDs from completing for ' + cast(@ThresholdMins/2 as varchar) + ' minutes.</p><p>This table<sup>*</sup> shows the '
			+ 'queries at the head of the blocking chains, which are preventing other queries from proceeding.</p><table class="smallText" cellspacing="2" '
			+ 'cellpadding="3"><tr style="background-color:#C0C0C0;font-weight:bold"><th width="60">SPID</th><th width="150">Blocking Chain</th>'
			+ '<th width="150">Login Name</th><th width="150">Duration (mins)</th><th width="150">Host Name</th><th width="200">Program Name</th><th width="100">'
			+ 'Database</th><th width="250">Statement**</th></tr>';
		set @Class = ' class="odd"'
		-- Define cursor to loop through head of new blocking chain(s) and blocked sessions in those chain(s)
		declare cur_NewBlockingChains cursor for
		select top 10 blocked_spid
			, blocking_chain
			, isnull(login_name, '-') as login_name
			, datediff(minute, start_time, getdate()) as duration_mins
			, isnull(host_name, '-') as host_name			
			, isnull(program_name, '-') as program_name			 
			, isnull(database_name, '-') as database_name
			, isnull(left(sql_statement, 250), '-') as sql_statement
		from @BlockingChains 
		where blocking_spid in 
		(
			select *
			from @BlockingSPIDs
		)
		order by blocking_spid
			, blocked_spid
		-- Open the cursor
		open cur_NewBlockingChains;
		-- Fetch the details of first blocking/blocked SPID
		fetch cur_NewBlockingChains
		into @SPID
			, @BlockingChain
			, @LoginName
			, @DurationMins
			, @HostName
			, @ProgramName
			, @DatabaseName
			, @SqlStatement;
		-- Loop through the details of blocking/blocked SPIDs
		while (@@fetch_status = 0)
		begin
			-- Add the row to the table
			set @Message = @Message
				+ '<tr' + @Class + '><td>' + cast(@SPID as varchar) + '</td>' 
				+ '<td>' + cast(@BlockingChain as varchar) + '</td>' 				
				+ '<td>' + cast(@LoginName as varchar) + '</td>'
				+ '<td style="text-align:center">' + cast(@DurationMins as varchar) + '</td>'
				+ '<td>' + left(cast(@HostName as varchar), 50) + '</td>'
				+ '<td>' + left(cast(@ProgramName as varchar), 50) + '</td>'
				+ '<td>' + @DatabaseName + '</td>'
				+ '<td>' + @SqlStatement + '</td></tr>'
			-- Change the row color
			if @Class = ' class="odd"' 
				set @Class = ' class="even"';
			else
				set @Class = ' class="odd"';
			-- Fetch the details of next blocking/blocked SPID
			fetch cur_NewBlockingChains
			into @SPID
				, @BlockingChain
				, @LoginName
				, @DurationMins
				, @HostName
				, @ProgramName
				, @DatabaseName
				, @SqlStatement;
		end
		-- Close and deallocate the cursor
		close cur_NewBlockingChains;
		deallocate cur_NewBlockingChains;
		-- End the message body
		set @Message = @Message + '</table><span class="footnote"> *  Top 10 results only<br/> ** Limited to 250 characters</span><p>It is recommended that the SPID(s) identified '
			+ 'as ''Head of chain'' in the table below are investigated further, with the aim of either:</p><p><ul><li>Ensuring that there are no pending application '
			+ 'processes preventing the SPID from completing. E.g. an application dialog waiting on a user to select an option.</li><li>Manually stopping & rolling '
			+ 'back the process.</li><li>Identifying whether this is normal behaviour and allowing the process to complete. If this is the case, please request that '
			+ 'the alert threshold, which currently set to ' + cast(@ThresholdMins/2 as varchar)  + ' minutes, be increased to avoid further false positive alerting.</li>'
			+ '<li>Reviewing the code being executed with the application developer, with the aim of fine tuning it''s locking mechanism.</li></ul></p><p><b><u>'
			+ 'Background on Blocking</u></b><br/>Blocking is a normal characteristic of any relational database management system (RDBMS) with lock-based concurrency, '
			+ 'so occasional blocking is to be expected. Within SQL Server, blocking occurs when a SPID holds a lock on a specific resource and subsequent processes '
			+ 'attempt to acquire a conflicting lock type on the same resource.</p></body></html>';

		-- Send the alert for the new blocking chain(s)
		exec dbo.up_SendMail 'Alert_SSL_Blocking_custom', @Message 

		-- Store the head of each new blocking chain
		insert into tbl_BlockingSPIDs
		select blocking_spid
			, start_time
			, null
			, isnull(login_name, '')
			, isnull(host_name, '')
			, isnull(program_name, '')
			, isnull(database_name, '')
			, isnull(left(sql_statement, 250), '')
			, blocked_spids
		from @BlockingChains 
		where blocking_spid = blocked_spid
			and blocking_spid in 
			(
				select *
				from @BlockingSPIDs
			);
		
		-- Empty the table variable for re-use	
		delete @BlockingSPIDs;
	end		

	/*--------------------------------------------------------------------------------------------
	* Process flow step: New head of chain(s) found in past blocking chain(s) with breached threshold?
	* If yes, then send Alert_SSL_BlockingChanged alert
	*-------------------------------------------------------------------------------------------*/
	insert into @BlockingSPIDs 
	select bs.blocking_spid
	from @BlockingChains bs
	where bs.blocking_spid = bs.blocked_spid 
		and datediff(minute, start_time, getdate()) > @ThresholdMins/2
		and exists 
		(
			select 1 
			from tbl_BlockingSPIDs 
			where EndDate is null
				and BlockingSPID <> bs.blocking_spid
				and 
				(
					BlockedSPIDs = cast(bs.blocking_spid as varchar)
						or BlockedSPIDs like cast(bs.blocking_spid as varchar) + ',%'
						or BlockedSPIDs like '%,' + cast(bs.blocking_spid as varchar)
						or BlockedSPIDs like '%,' + cast(bs.blocking_spid as varchar) + ',%'
				)
		);

	if exists
	(
		select 1
		from @BlockingSPIDs
	)
	begin
		-- Compose the message body
		set @Message = '<html><head><style>.smallText {font-size:10pt;font-family:Arial} .even {background-color:#C0C0C0} .odd {background-color:#DCDCDC} .center '
			+ '{text-align:center} table {table-layout:fixed;width:1210px} table td {word-wrap:break-word;vertical-align:top} .footnote {font-size:9pt;color:#FF0000}'
			+ '</style></head><body class="smallText"><p>The following SPID(s) on ' +  @ServerName + ' were previously alerted as being the head of the blocking chain(s) '
			+ 'for longer than ' + cast(@ThresholdMins/2 as varchar) + ' minutes, but there has been a change in the blocking chain(s):</p><table class="smallText" '
			+ 'cellspacing="2" cellpadding="3"><tr style="background-color:#C0C0C0;font-weight:bold"><th width="60">SPID</th><th width="150">Blocking Chain'
			+ '</th><th width="150">Login Name</th><th width="150">Duration (mins)</th><th width="150">Host Name</th><th width="200">Program Name</th><th width="100">'
			+ 'Database</th><th width="250">Statement*</th></tr>';
		set @Class = ' class="odd"'
		-- Define cursor to loop through head of changed blocking chain(s) and blocked sessions in those chain(s)
		declare cur_ChangedBlockingChains cursor for
		select * from 
		(
			select blocked_spid
				, blocking_chain
				, isnull(login_name, '-') as login_name
				, datediff(minute, start_time, getdate()) as duration_mins
				, isnull(host_name, '-') as host_name			
				, isnull(program_name, '-') as program_name			 
				, isnull(database_name, '-') as database_name
				, isnull(left(sql_statement, 250), '-') as sql_statement
			from @BlockingChains 
			where blocking_spid in 
			(
				select *
				from @BlockingSPIDs
			)
			union all
			select BlockingSPID
				, 'No longer blocking'
				, case when rtrim(ltrim(LoginName)) = '' then '-' else LoginName end
				, '-'
				, case when rtrim(ltrim(HostName)) = '' then '-' else HostName end
				, case when rtrim(ltrim(ProgramName)) = '' then '-' else ProgramName end
				, case when rtrim(ltrim(DatabaseName)) = '' then '-' else DatabaseName end
				, case when rtrim(ltrim(Statement)) = '' then '-' else Statement end
			from tbl_BlockingSPIDs tbs
				inner join @BlockingSPIDs bs on tbs.BlockedSPIDs = cast(bs.blocking_spid as varchar)
						or tbs.BlockedSPIDs like cast(bs.blocking_spid as varchar) + ',%'
						or tbs.BlockedSPIDs like '%,' + cast(bs.blocking_spid as varchar)
						or tbs.BlockedSPIDs like '%,' + cast(bs.blocking_spid as varchar) + ',%'
			where tbs.EndDate is null
		) T
		order by case when blocking_chain = 'No longer blocking' then 1 else 2 end , 1
		-- Open the cursor
		open cur_ChangedBlockingChains;
		-- Fetch the details of first blocking/blocked SPID
		fetch cur_ChangedBlockingChains
		into @SPID
			, @BlockingChain
			, @LoginName
			, @DurationMins
			, @HostName
			, @ProgramName
			, @DatabaseName
			, @SqlStatement;
		-- Loop through the details of blocking/blocked SPIDs
		while (@@fetch_status = 0)
		begin
			-- Add the row to the table
			set @Message = @Message
				+ '<tr' + @Class + '><td>' + cast(@SPID as varchar) + '</td>' 
				+ '<td>' + cast(@BlockingChain as varchar) + '</td>' 				
				+ '<td>' + cast(@LoginName as varchar) + '</td>'
				+ '<td style="text-align:center">' + cast(@DurationMins as varchar) + '</td>'
				+ '<td>' + left(cast(@HostName as varchar), 50) + '</td>'
				+ '<td>' + left(cast(@ProgramName as varchar), 50) + '</td>'
				+ '<td>' + @DatabaseName + '</td>'
				+ '<td>' + @SqlStatement + '</td></tr>'
			-- Change the row color
			if @Class = ' class="odd"' 
				set @Class = ' class="even"';
			else
				set @Class = ' class="odd"';
			-- Fetch the details of next blocking/blocked SPID
			fetch cur_ChangedBlockingChains
			into @SPID
				, @BlockingChain
				, @LoginName
				, @DurationMins
				, @HostName
				, @ProgramName
				, @DatabaseName
				, @SqlStatement;
		end
		-- Close and deallocate the cursor
		close cur_ChangedBlockingChains;
		deallocate cur_ChangedBlockingChains;
		-- End the message body
		set @Message = @Message + '</table><span class="footnote"> * Limited to 250 characters</span><p>It is recommended to:</p><p><ul><li>Where applicable, '
			+ 'investigate any head of chain processes in the above table flagged as "Still blocking".</li><li>Review the remaining processes running on ' + @ServerName 
			+ ' to ensure that they are now able to complete successfully given that the head of the blocking chain has since cleared.</li><li>Review the code '
			+ 'being executed with the aim of fine-tuning its locking requirements.</li></ul></p></body></html>';

		-- Send the alert for the new blocking chain(s)
		exec dbo.up_SendMail 'Alert_SSL_BlockingChanged_custom', @Message 
		-- Update the end date for head(s), found in past blocking chain(s), which are now cleared
		update tbs 
		set EndDate = getdate()
		from tbl_BlockingSPIDs tbs
			inner join @BlockingSPIDs bs on tbs.BlockedSPIDs = cast(bs.blocking_spid as varchar)
				or tbs.BlockedSPIDs like cast(bs.blocking_spid as varchar) + ',%'
				or tbs.BlockedSPIDs like '%,' + cast(bs.blocking_spid as varchar)
				or tbs.BlockedSPIDs like '%,' + cast(bs.blocking_spid as varchar) + ',%'
		where tbs.EndDate is null
		-- Store the new head(s) with breached threshold, found in past blocking chain(s), 
		insert into tbl_BlockingSPIDs
		select blocking_spid
			, start_time
			, null
			, isnull(login_name, '')
			, isnull(host_name, '')
			, isnull(program_name, '')
			, isnull(database_name, '')
			, isnull(left(sql_statement, 250), '')
			, blocked_spids
		from @BlockingChains 
		where blocking_spid = blocked_spid
			and blocking_spid in 
			(
				select *
				from @BlockingSPIDs
			)		
		-- Empty the table variable for re-use
		delete @BlockingSPIDs;
	end			
		
	/*--------------------------------------------------------------------------------------------
	* Process flow step: Fully cleared head of chain(s) found?
	* If yes, then send Alert_SSL_BlockingEnded alert
	*-------------------------------------------------------------------------------------------*/
	if exists
	(
		select 1
		from tbl_BlockingSPIDs 
		where EndDate is null
			and BlockingSPID not in 
			(
				select distinct blocking_spid
				from @BlockingChains
			)
	)
	begin
		-- Compose the message body
		set @Message = '<html><head><style>.smallText {font-size:10pt;font-family:Arial} .even {background-color:#C0C0C0} .odd {background-color:#DCDCDC} .center '
			+ '{text-align:center} table {table-layout:fixed;width:1060px} table td {word-wrap:break-word;vertical-align:top} .footnote {font-size:9pt;color:#FF0000}'
			+ '</style></head><body class="smallText"><p>The following SPID(s) on ' +  @ServerName + ' were previously alerted as being the head of the blocking chain(s) '
			+ 'for longer than ' + cast(@ThresholdMins/2 as varchar) + ' minutes, but are now no longer blocking:</p><table class="smallText" cellspacing="2" cellpadding="3">'
			+ '<tr style="background-color:#C0C0C0;font-weight:bold"><th width="60">SPID</th><th width="150">Blocking Chain</th><th width="150">Login Name</th>'
			+ '<th width="150">Host Name</th><th width="200">Program Name</th><th width="100">Database</th><th width="250">Statement*</th></tr>';
		set @Class = ' class="odd"'
		-- Define cursor to loop through head of blocking chain(s) which are now cleared
		declare cur_EndedBlockingChains cursor for
		select BlockingSPID
			, 'No longer blocking'
			, case when rtrim(ltrim(LoginName)) = '' then '-' else LoginName end
			, case when rtrim(ltrim(HostName)) = '' then '-' else HostName end
			, case when rtrim(ltrim(ProgramName)) = '' then '-' else ProgramName end
			, case when rtrim(ltrim(DatabaseName)) = '' then '-' else DatabaseName end
			, case when rtrim(ltrim(Statement)) = '' then '-' else Statement end
		from tbl_BlockingSPIDs 
		where EndDate is null
			and BlockingSPID not in 
			(
				select *
				from @BlockingSPIDs
			)
		order by BlockingSPID
		-- Open the cursor
		open cur_EndedBlockingChains;
		-- Fetch the details of first blocking/blocked SPID
		fetch cur_EndedBlockingChains
		into @SPID
			, @BlockingChain
			, @LoginName
			, @HostName
			, @ProgramName
			, @DatabaseName
			, @SqlStatement;
		-- Loop through the details of blocking/blocked SPIDs
		while (@@fetch_status = 0)
		begin
			-- Add the row to the table
			set @Message = @Message
				+ '<tr' + @Class + '><td>' + cast(@SPID as varchar) + '</td>' 
				+ '<td>' + cast(@BlockingChain as varchar) + '</td>' 				
				+ '<td>' + cast(@LoginName as varchar) + '</td>'
				+ '<td>' + left(cast(@HostName as varchar), 50) + '</td>'
				+ '<td>' + left(cast(@ProgramName as varchar), 50) + '</td>'
				+ '<td>' + @DatabaseName + '</td>'
				+ '<td>' + @SqlStatement + '</td></tr>'
			-- Change the row color
			if @Class = ' class="odd"' 
				set @Class = ' class="even"';
			else
				set @Class = ' class="odd"';
			-- Fetch the next cleared head of chain
			fetch cur_EndedBlockingChains
			into @SPID
				, @BlockingChain
				, @LoginName
				, @HostName
				, @ProgramName
				, @DatabaseName
				, @SqlStatement;
		end
		-- Close and deallocate the cursor
		close cur_EndedBlockingChains;
		deallocate cur_EndedBlockingChains;
		-- End the message body
		set @Message = @Message + '</table><span class="footnote"> * Limited to 250 characters</span></body></html>';

		-- Send the alert for the cleared blocking chain(s)
		exec dbo.up_SendMail 'Alert_SSL_BlockingEnded_custom', @Message
		
		-- Update the end date for cleared head of chain SPIDs
		update tbl_BlockingSPIDs 
		set EndDate = getdate()
		where EndDate is null
			and BlockingSPID not in 
			(
				select *
				from @BlockingSPIDs
			)		
	end			
				
end
go