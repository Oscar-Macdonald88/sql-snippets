declare @JobID binary(16)
		, @CmdString varchar(4000)
		, @SSL_DailyBackupTime int		
		, @SSL_DailyBackupFreqType int
		, @SSL_DailyBackupFreqInterval int
		, @EnableJob nChar(1)
		, @Step_Id int
		, @AdditionalJobName varChar(255)
		, @sa_user sysname
		, @JobName sysname

set @CmdString = N'if exists (select 1
from SSLDBA.dbo.tbl_DBCC_Control
where CheckDate is null)
select ''Running DBCC CheckTable from last end point''
else
begin
       update SSLDBA.dbo.tbl_DBCC_Control set CheckDate = null
       select ''Running DBCC CheckTable from the begining''
end

declare @StartTime DateTime
set @StartTime = getdate()
declare @Duration int
set @Duration = 30
declare @DBName sysname
declare @SchemaName sysname
declare @ObjectName sysname
declare @database_object SYSNAME

select @DBName = (select top 1
              DBName
       from SSLDBA.dbo.tbl_DBCC_Control
       where (CheckDate > (select max(CheckDate)
              from SSLDBA.dbo.tbl_DBCC_Control)
              or CheckDate is null)
              and [WeekDay] = DATEPART ( weekday , getdate() )
       order by DBName, TableName)

while @DBName > '''' and DATEDIFF(minute, @StartTime,getdate()) < @Duration
begin
       select @SchemaName = (select top 1
                     SchemaName
              from SSLDBA.dbo.tbl_DBCC_Control
              where  (CheckDate > (select max(CheckDate)
                     from SSLDBA.dbo.tbl_DBCC_Control)
                     or CheckDate is null)
                     and [WeekDay] = DATEPART ( weekday , getdate() )
              order by DBName, TableName)

       select @ObjectName = (select top 1
                     TableName
              from SSLDBA.dbo.tbl_DBCC_Control
              where  (CheckDate > (select max(CheckDate)
                     from SSLDBA.dbo.tbl_DBCC_Control)
                     or CheckDate is null)
                     and [WeekDay] = DATEPART ( weekday , getdate() )
              order by DBName, TableName)

       set @database_object = @DBName + ''.''+ @SchemaName + ''.'' + @ObjectName

       IF OBJECT_ID (@database_object, N''U'') IS NOT NULL
       BEGIN

              INSERT INTO SSLDBA.dbo.tbl_DBCC_History
                     ([Error], [Level], [State], [MessageText], [RepairLevel], [Status], [DbId], [DbFragId],
                     [ObjectId], [IndId], [PartitionID], [AllocUnitID], [RidDbId], [RidPruId], [File], [Page], [Slot],
                     [RefDbId], [RefPruId], [RefFile], [RefPage], [RefSlot], [Allocation])
              EXEC (''dbcc checktable('''''' + @database_object + '''''') with tableresults'')

              update SSLDBA.dbo.tbl_DBCC_Control set CheckDate = getdate() 
              where DBName = @DBName and TableName = @ObjectName

              select @DBName = (select top 1
                            DBName
                     from SSLDBA.dbo.tbl_DBCC_Control
                     where (CheckDate > (select max(CheckDate)
                            from SSLDBA.dbo.tbl_DBCC_Control)
                            or CheckDate is null)
                            and [WeekDay] = DATEPART ( weekday , getdate() )
                     order by DBName, TableName)
              select @DBName = ISNULL(@DBName,'''')
       END
end'
		
	-- Get the 'sa' user name - usually it's 'sa' but as this can be renamed on some servers we will extract it
	set @sa_user = suser_sname(0x01)

	set @JobName = 'SSL_Distributed_DBCC'
			
	if (select count(*) from msdb.dbo.syscategories where name = N'SSL Template') < 1 
	  execute msdb.dbo.sp_add_category @name = N'SSL Template'

	-- Drop the job if it exists
	if exists (select 1 from msdb..sysjobs where name = @JobName)
	begin
		delete from msdb..sysjobs where name = @JobName 
	end
 -- Job doesn't exist, so lets create it
    select @JobID = null
    -- Add the job
    execute msdb.dbo.sp_add_job
        @job_id = @JobID output
        , @job_name = @JobName
        , @owner_login_name = @sa_user
        , @description = N'This job was create by SQL Services Ltd. Please do not delete.'
        , @category_name = N'SSL Template'
        , @enabled = 1
        , @notify_level_page = 0
        , @notify_level_eventlog = 3
        , @delete_level = 0

    -- Add the target servers
    execute msdb.dbo.sp_add_jobserver @job_id = @JobID, @server_name = N'(local)' 

	select @Step_Id = 1
	
	-- Add the job steps
    select @StepName_str = 'Backup ' + @dbname
    select @ReportFileName = (select top 1 TextValue + 'Backup_' + dbo.uf_CorrectFileName(@dbname) + '.out' from dbo.tbl_Param where Param = 'SQLReportsDir')

    execute msdb.dbo.sp_add_jobstep
        @job_name = @JobName
        , @step_id = @Step_Id
        , @step_name = @StepName_str
        , @database_name =  N'SSLDBA'
        , @command = @CmdString
        , @flags = 4
        , @retry_attempts = 0
        , @retry_interval = 1
        , @on_success_action = 3 -- how can I get to 
        , @on_fail_action = 3 -- what is the correct action for this?

    select @Step_Id = @Step_Id + 1

	-- Add a step to send out an email and/or page containing the list of failed backups to DBAs
	execute msdb.dbo.sp_add_jobstep
		@job_name =  @JobName
		, @step_id = @Step_Id
		, @step_name = N'Check for failed job steps'
		, @command = 'Exec dbo.up_CheckJobStepFailure ''' + @JobName + ''''
		, @flags = 4
		, @on_success_action = 3 -- what is the correct action for this?
		, @on_fail_action = 3 -- what is the correct action for this?
		, @database_name =  N'SSLDBA'
		, @retry_attempts = 2
		, @retry_interval = 1

		select @Step_Id = @Step_Id +1

	-- If we need to run an additional step after the backups are completed then create the addtional step
	select @AdditionalJobName = isnull((select top 1 TextValue from dbo.tbl_Param where Param = 'AdditionalBackupAllDBJobName'), '')
	if @AdditionalJobName <> '' 
	begin
		select @StepName_str = 'Start the Additional Job: ' + @AdditionalJobName

		select @CmdString = 'exec msdb.dbo.sp_start_job '''+@AdditionalJobName+''''    	

		-- We have an additional job to run at the end of the backups. Currently used for RBackup
		execute msdb.dbo.sp_add_jobstep 
			@job_name = @JobName
			, @step_id = @Step_Id
			, @step_name = @StepName_str
			, @command = @CmdString
			, @database_name = N'msdb'
			, @flags = 4
			, @retry_attempts = 2
			, @retry_interval = 1
			, @on_success_action = 3
			, @on_fail_action = 3

		select @Step_Id = @Step_Id +1
	end

	-- Now add the final steps
	execute msdb.dbo.sp_add_jobstep 
		@job_name = @JobName
		, @step_id = @Step_Id
		, @step_name = N'Create Backup Report'
		, @command = 'Exec SSLDBA.dbo.up_Backup_Report'
		, @database_name = N'SSLDBA'
		, @flags = 4
		, @retry_attempts =  2
		, @retry_interval = 1
		, @output_file_name = N''
		, @on_success_action = 3
		, @on_fail_action = 3
	
	select @Step_Id = @Step_Id + 1

	execute msdb.dbo.sp_add_jobstep
		@job_name = @JobName
		, @step_id = @Step_Id
		, @step_name = N'Send Backup Report'
		, @command = 'Exec dbo.up_SendMail ''Daily''; if exists (select * from dbo.tbl_Databases_AlwaysOn_Support) begin if exists (select * from SSLDBA.dbo.vw_BackupSetAlwaysOn) Exec dbo.up_SendMail ''DailyAlwaysOn'' end'
		, @database_name = N'SSLDBA'
		, @flags = 4
		, @retry_attempts = 2
		, @retry_interval = 1
		, @on_success_action = 3
		, @on_fail_action = 3

	select @Step_Id = @Step_Id + 1

	select @CmdString = 'Exec dbo.up_CheckJobStepFailure '''+@JobName+'''' 	
	
	execute msdb.dbo.sp_add_jobstep
		@job_name = @JobName
		, @step_id = @Step_Id
		, @step_name = N'Check for failed job steps'
		, @command = @CmdString
		, @database_name = N'SSLDBA'
		, @flags = 4
		, @on_success_action = 1
		, @on_fail_action = 2
		
	execute msdb.dbo.sp_update_job @job_name = @JobName, @start_step_id = 1
		
	select @SSL_DailyBackupTime = NumValue from dbo.tbl_Param where Param =  'DailyBackupStartTime'
	
	select @SSL_DailyBackupFreqType = isnull((select NumValue from dbo.tbl_Param where Param =  'DailyBackupFreqType'), 4)
	
	select @SSL_DailyBackupFreqInterval = isnull((select NumValue from dbo.tbl_Param where Param =  'DailyBackupFreqInterval'), 1)
		
	-- Add the job schedule
	execute msdb.dbo.sp_add_jobschedule
		@job_name = @JobName
		, @name = @JobName
		, @enabled = 1
		, @freq_type = @SSL_DailyBackupFreqType
		, @active_start_date = 20010101
		, @active_start_time = @SSL_DailyBackupTime
		, @freq_interval = @SSL_DailyBackupFreqInterval
		, @freq_subday_type = 1
		, @freq_subday_interval = 0
		, @freq_relative_interval = 0
		, @freq_recurrence_factor = 1
		, @active_end_date = 99991231
		, @active_end_time = 235959
  
end
go