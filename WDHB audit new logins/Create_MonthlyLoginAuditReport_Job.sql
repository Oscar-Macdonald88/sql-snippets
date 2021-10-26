USE [msdb]
GO

/****** Object:  Job [SSL_MonthlyLoginAuditReport]    Script Date: 22/01/2019 4:57:20 p.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 22/01/2019 4:57:20 p.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SSL_MonthlyLoginAuditReport', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Sends a report containing a list of all newly created logins in the iPM environment', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Generate and send report]    Script Date: 22/01/2019 4:57:20 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Generate and send report', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'if OBJECT_ID(''tempdb..#tmpLoginAudit'', ''U'') is not null
	drop table #tmpLoginAudit;
go

create table #tmpLoginAudit (
	event_time varchar(100),
	server_instance_name sysname,
	server_principal_name sysname,
	object_name sysname
	);
go

-- copy this section for each audit file
insert into #tmpLoginAudit
select convert(varchar, format(event_time, ''yyyy/MM/dd hh:mm tt'')),
	server_instance_name,
	server_principal_name,
	object_name
from sys.fn_get_audit_file(''\\WAI-SQL-P-027\Audits\*.sqlaudit'', default, default)
where action_id = ''CR'' -- CREATE events
	and event_time > DATEADD(month, - 1, GETDATE());-- get all events up to 1 month ago.
go


if ((select count(*) from #tmpLoginAudit) > 0)
	declare @today datetime;

	set @today = getdate();

	declare @tableName nvarchar(100) = ''Monthly ''''New Login'''' Audit: '' + convert(varchar, format(@today, ''dd-MM-yy''));
	declare @tableHTML nvarchar(MAX);

	set @tableHTML = N''<H1>'' + @tableName + '' </H1>'' 
	+ N''<table border="1">'' 
	+ N''<tr><th>Day / Time</th><th>Instance</th>'' 
	+ N''<th>Executed by</th><th>New Login</th>'' 
	+ cast((
				select td = event_time,
					'''',
					td = server_instance_name,
					'''',
					td = server_principal_name,
					'''',
					td = object_name
				from #tmpLoginAudit
				for xml PATH(''tr''),
					TYPE
				) as nvarchar(max)) + N''</table>'';

	print @tableHTML;
		EXEC msdb..sp_send_dbmail
		@profile_name = ''ManagedSQL'',
		@recipients = ''oscar.macdonald@sqlservices.com'',
		@subject = ''Monthly ''''New Login'''' Audit'',
		@body = @tableHTML,
		@body_format = ''HTML'';
go
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'SSL_LoginAuditMonthly', 
		@enabled=1, 
		@freq_type=16, 
		@freq_interval=28, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20181127, 
		@active_end_date=99991231, 
		@active_start_time=30500, 
		@active_end_time=235959, 
		@schedule_uid=N'5916fe76-bde2-43e0-ada9-9cf5ac5ded1c'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


