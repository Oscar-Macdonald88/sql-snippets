USE [msdb]
GO

/****** Object:  Job [SSL_Ad-Hoc_Load_Rolled_TraceFiles]    Script Date: 29/09/2017 4:54:41 p.m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [SSL Template]    Script Date: 29/09/2017 4:54:41 p.m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'SSL Template' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'SSL Template'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SSL_Ad-Hoc_Load_Rolled_TraceFiles', 
		@enabled=0, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This job has been created by SQL Services Ltd.  Please do not change or delete.', 
		@category_name=N'SSL Template', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Adhoc Task]    Script Date: 29/09/2017 4:54:41 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Adhoc Task', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=6, 
		@retry_attempts=2, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'set nocount on

if object_id(''tempdb..#tmpTableTracePMF'') is not null
       drop table #tmpTableTracePMF

declare @perflogs varchar(128), @CMD varchar(128), @ServerName varchar(255)
declare @TraceFile varchar(255)
declare @Processed bit

create table #tmpTableTracePMF 
(
       TraceFile varchar(500)
)

set @ServerName = Replace(CONVERT(VARCHAR(255),ISNULL(SERVERPROPERTY(''ServerName''),'''')),''\'',''_'')
set @perflogs = (select TextValue from SSLMDW.ssl.Parameter where ParamName=''PMFDir'')
set @CMD = ''dir "'' + @perflogs + ''\*.trc" /b /od''

insert #tmpTableTracePMF exec xp_cmdshell @CMD

alter table #tmpTableTracePMF add Processed bit 
delete from #tmpTableTracePMF  where TraceFile is null


select * from #tmpTableTracePMF where Processed is null and TraceFile <> ''SSL_'' + @ServerName + ''_TraceFile.trc''


while exists (select * from #tmpTableTracePMF where Processed is null and TraceFile <> ''SSL_'' + @ServerName + ''_TraceFile.trc'')
begin
       select top 1 
              @TraceFile = TraceFile
              ,@Processed = Processed
              , @CMD = ''EXEC SSLMDW.ssl.up_TraceLoadInstance ''''''+ @ServerName +'''''', ''''''+@perflogs + ''\'' + TraceFile + '''''''' 
       from 
              #tmpTableTracePMF 
       where 
              TraceFile IS NOT NULL AND TraceFile NOT IN (''File Not Found'') AND TraceFile NOT LIKE ''%_TraceFile.trc''
              and Processed is null
       order by
              TraceFile desc
       
       update #tmpTableTracePMF set Processed = 1 where TraceFile = @TraceFile
       print @CMD
       execute(@CMD)
end


if object_id(''tempdb..#tmpTableTracePMF'') is not null
       drop table #tmpTableTracePMF
', 
		@database_name=N'SSLDBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Email Client on Success]    Script Date: 29/09/2017 4:54:41 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Email Client on Success', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=2, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec up_SendMail ''SQLAgentJob_SSL_Ad-Hoc_Load_Rolled_TraceFiles_Success''', 
		@database_name=N'SSLDBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Email Team Alert Board on Success]    Script Date: 29/09/2017 4:54:41 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Email Team Alert Board on Success', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=2, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec up_SendMail ''SQLAgentJob_SSL_Ad-Hoc_Load_Rolled_TraceFiles_Success''', 
		@database_name=N'SSLDBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Page On Call DBA on Success]    Script Date: 29/09/2017 4:54:41 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Page On Call DBA on Success', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=2, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec up_SendMail ''SQLAgentJob_SSL_Ad-Hoc_Load_Rolled_TraceFiles_Success''', 
		@database_name=N'SSLDBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Email Client on Failure]    Script Date: 29/09/2017 4:54:41 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Email Client on Failure', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=2, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec up_SendMail ''SQLAgentJob_SSL_Ad-Hoc_Load_Rolled_TraceFiles_Failure''', 
		@database_name=N'SSLDBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Email Team Alert Board on Failure]    Script Date: 29/09/2017 4:54:41 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Email Team Alert Board on Failure', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=2, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec up_SendMail ''SQLAgentJob_SSL_Ad-Hoc_Load_Rolled_TraceFiles_Failure''', 
		@database_name=N'SSLDBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Page On Call DBA on Failure]    Script Date: 29/09/2017 4:54:41 p.m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Page On Call DBA on Failure', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=2, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec up_SendMail ''SQLAgentJob_SSL_Ad-Hoc_Load_Rolled_TraceFiles_Failure''', 
		@database_name=N'SSLDBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Adhoc Schedule - SSL_Ad-Hoc_Load_Rolled_TraceFiles', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20160602, 
		@active_end_date=99991231, 
		@active_start_time=235000, 
		@active_end_time=235959, 
		@schedule_uid=N'db330df0-6ee6-415e-874d-5053e9ed313d'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


