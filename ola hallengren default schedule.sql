USE [msdb]
GO
DECLARE @schedule_id int

IF NOT EXISTS(
	SELECT *
	FROM
		msdb.dbo.sysjobs AS j
		INNER JOIN msdb.dbo.sysjobschedules AS sjs ON j.job_id = sjs.job_id
		INNER JOIN msdb.dbo.sysschedules AS ss ON sjs.schedule_id = ss.schedule_id
	WHERE
		j.name = 'CommandLog Cleanup'

)
BEGIN;

	EXEC msdb.dbo.sp_add_jobschedule @job_name=N'CommandLog Cleanup', @name=N'maint_clean', 
			@enabled=1, 
			@freq_type=8, 
			@freq_interval=32, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20180115, 
			@active_end_date=99991231, 
			@active_start_time=0, 
			@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
	select @schedule_id
END;
GO

USE [msdb]
GO
DECLARE @schedule_id int

IF NOT EXISTS(
	SELECT *
	FROM
		msdb.dbo.sysjobs AS j
		INNER JOIN msdb.dbo.sysjobschedules AS sjs ON j.job_id = sjs.job_id
		INNER JOIN msdb.dbo.sysschedules AS ss ON sjs.schedule_id = ss.schedule_id
	WHERE
		j.name = 'DatabaseBackup - SYSTEM_DATABASES - FULL'
)
BEGIN;
	EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DatabaseBackup - SYSTEM_DATABASES - FULL', @name=N'maint_sys_backups', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20180115, 
			@active_end_date=99991231, 
			@active_start_time=223000, 
			@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
	select @schedule_id
END
GO

USE [msdb]
GO
DECLARE @schedule_id int

IF NOT EXISTS(
	SELECT *
	FROM
		msdb.dbo.sysjobs AS j
		INNER JOIN msdb.dbo.sysjobschedules AS sjs ON j.job_id = sjs.job_id
		INNER JOIN msdb.dbo.sysschedules AS ss ON sjs.schedule_id = ss.schedule_id
	WHERE
		j.name = 'DatabaseBackup - USER_DATABASES - FULL'
)
BEGIN;
	EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DatabaseBackup - USER_DATABASES - FULL', @name=N'maint_user_backups_full', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20180115, 
			@active_end_date=99991231, 
			@active_start_time=223500, 
			@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
	select @schedule_id
END;
GO

USE [msdb]
GO
DECLARE @schedule_id int

IF NOT EXISTS(
	SELECT *
	FROM
		msdb.dbo.sysjobs AS j
		INNER JOIN msdb.dbo.sysjobschedules AS sjs ON j.job_id = sjs.job_id
		INNER JOIN msdb.dbo.sysschedules AS ss ON sjs.schedule_id = ss.schedule_id
	WHERE
		j.name = 'DatabaseBackup - USER_DATABASES - DIFF'
)
BEGIN;
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DatabaseBackup - USER_DATABASES - DIFF', @name=N'maint_user_backups_diff', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=6, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20200730, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
END;
GO

USE [msdb]
GO
DECLARE @schedule_id int

IF NOT EXISTS(
	SELECT *
	FROM
		msdb.dbo.sysjobs AS j
		INNER JOIN msdb.dbo.sysjobschedules AS sjs ON j.job_id = sjs.job_id
		INNER JOIN msdb.dbo.sysschedules AS ss ON sjs.schedule_id = ss.schedule_id
	WHERE
		j.name = 'DatabaseIntegrityCheck - SYSTEM_DATABASES'
)
BEGIN;
	EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DatabaseIntegrityCheck - SYSTEM_DATABASES', @name=N'maint_sys_dbcc', 
			@enabled=1, 
			@freq_type=8, 
			@freq_interval=1, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20180115, 
			@active_end_date=99991231, 
			@active_start_time=0, 
			@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
	select @schedule_id
END;
GO

USE [msdb]
GO
DECLARE @schedule_id int

IF NOT EXISTS(
	SELECT *
	FROM
		msdb.dbo.sysjobs AS j
		INNER JOIN msdb.dbo.sysjobschedules AS sjs ON j.job_id = sjs.job_id
		INNER JOIN msdb.dbo.sysschedules AS ss ON sjs.schedule_id = ss.schedule_id
	WHERE
		j.name = 'DatabaseIntegrityCheck - USER_DATABASES'
)
BEGIN;
	EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DatabaseIntegrityCheck - USER_DATABASES', @name=N'maint_user_dbcc', 
			@enabled=1, 
			@freq_type=8, 
			@freq_interval=1, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20180115, 
			@active_end_date=99991231, 
			@active_start_time=1500, 
			@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
	select @schedule_id
END;
GO

USE [msdb]
GO
DECLARE @schedule_id int

IF NOT EXISTS(
	SELECT *
	FROM
		msdb.dbo.sysjobs AS j
		INNER JOIN msdb.dbo.sysjobschedules AS sjs ON j.job_id = sjs.job_id
		INNER JOIN msdb.dbo.sysschedules AS ss ON sjs.schedule_id = ss.schedule_id
	WHERE
		j.name = 'IndexOptimize - USER_DATABASES'
)
BEGIN;
	EXEC msdb.dbo.sp_add_jobschedule @job_name=N'IndexOptimize - USER_DATABASES', @name=N'maint_user_indexing', 
			@enabled=1, 
			@freq_type=8, 
			@freq_interval=64, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20180115, 
			@active_end_date=99991231, 
			@active_start_time=500, 
			@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
	select @schedule_id
END;
GO

USE [msdb]
GO
DECLARE @schedule_id int

IF NOT EXISTS(
	SELECT *
	FROM
		msdb.dbo.sysjobs AS j
		INNER JOIN msdb.dbo.sysjobschedules AS sjs ON j.job_id = sjs.job_id
		INNER JOIN msdb.dbo.sysschedules AS ss ON sjs.schedule_id = ss.schedule_id
	WHERE
		j.name = 'DatabaseBackup - USER_DATABASES - LOG'
)
BEGIN;
	EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DatabaseBackup - USER_DATABASES - LOG', @name=N'maint_user_backups_log', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=4, 
			@freq_subday_interval=15, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20180116, 
			@active_end_date=99991231, 
			@active_start_time=0, 
			@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
	select @schedule_id
END;
GO

USE [msdb]
GO

DECLARE @schedule_id int

IF NOT EXISTS(

	SELECT *
	FROM
		msdb.dbo.sysjobs AS j
		INNER JOIN msdb.dbo.sysjobschedules AS sjs ON j.job_id = sjs.job_id
		INNER JOIN msdb.dbo.sysschedules AS ss ON sjs.schedule_id = ss.schedule_id
	WHERE
		j.name = 'sp_delete_backuphistory'

)
BEGIN;

	EXEC msdb.dbo.sp_add_jobschedule @job_name=N'sp_delete_backuphistory', @name=N'maint_purge_msdb', 
			@enabled=1, 
			@freq_type=4, 
			@freq_interval=1, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date = 20220330, 
			@active_end_date=99991231, 
			@active_start_time=0, 
			@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
	select @schedule_id
END;
GO

DECLARE @schedule_id int;

SELECT @schedule_id = schedule_id 
FROM msdb..sysschedules
WHERE name = 'maint_clean';

IF NOT EXISTS(
	SELECT *
	FROM
		msdb.dbo.sysjobs AS j
		INNER JOIN msdb.dbo.sysjobschedules AS sjs ON j.job_id = sjs.job_id
		INNER JOIN msdb.dbo.sysschedules AS ss ON sjs.schedule_id = ss.schedule_id
	WHERE
		j.name = 'Output File Cleanup'
)
BEGIN;
	EXEC msdb.dbo.sp_attach_schedule @job_name=N'Output File Cleanup',@schedule_id=@schedule_id;
	EXEC msdb.dbo.sp_attach_schedule @job_name=N'sp_purge_jobhistory',@schedule_id=@schedule_id;
END;
GO