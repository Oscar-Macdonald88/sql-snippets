--TEMPLATE and PMF Uninstall helper
SET NOCOUNT ON
DECLARE @CONFIRM VARCHAR(20) = 'PleaseConfirm' -- UNINSTALL PleaseConfirm
DECLARE @REMOVETEMPLATE VARCHAR(3) = 'No' -- Yes No
DECLARE @REMOVEPMF VARCHAR(3) = 'No' -- Yes No

IF (@CONFIRM = 'UNINSTALL') BEGIN
	IF (@REMOVEPMF = 'Yes') BEGIN
		BEGIN TRY
			exec master..sp_trace_setstatus 2,0
			exec master..sp_trace_setstatus 2,2
			PRINT 'Trace stopped'
		END TRY
		BEGIN CATCH
			PRINT 'Trace not running'
		END CATCH
		EXEC [msdb].[dbo].[sp_syscollector_delete_collection_set] @name='SSL PMF Counters'
		PRINT 'Data collector removed'
		IF EXISTS (SELECT 1 FROM msdb..sysjobs WHERE name ='SSL_PMF_Roll_Trace')
			EXEC msdb..sp_delete_job @job_name='SSL_PMF_Roll_Trace'
		IF EXISTS (SELECT 1 FROM msdb..sysjobs WHERE name ='SSL_PMF_CheckCollectorSets')
			EXEC msdb..sp_delete_job @job_name='SSL_PMF_CheckCollectorSets'
		IF EXISTS (SELECT 1 FROM msdb..sysjobs WHERE name ='SSL_PMF_ExtractData')
			EXEC msdb..sp_delete_job @job_name='SSL_PMF_ExtractData'
		IF EXISTS (SELECT 1 FROM msdb..sysjobs WHERE name ='mdw_purge_data_[SSLMDW]')
			EXEC msdb..sp_delete_job @job_name='mdw_purge_data_[SSLMDW]'
		PRINT 'Jobs removed'
		EXEC msdb..sp_UPDATE_job @job_name='sysutility_get_cache_tables_data_into_aggregate_tables_daily',@enabled = 0
		EXEC msdb..sp_UPDATE_job @job_name='sysutility_get_cache_tables_data_into_aggregate_tables_hourly',@enabled = 0
		EXEC msdb..sp_UPDATE_job @job_name='sysutility_get_views_data_into_cache_tables',@enabled = 0
		PRINT 'Sys jobs disabled'
		DROP DATABASE SSLMDW;
		DELETE FROM SSLDBA..tbl_Databases WHERE DatabaseName = 'SSLMDW'
		PRINT 'SSLMDW removed'
		DELETE FROM SSLDBA..tbl_Databases WHERE DatabaseName = 'SSLMDW'
		PRINT '-----------------------------------------------'
		PRINT '------------PMF UNINSTALL COMPLETED------------'
		PRINT '-----------------------------------------------'
		EXEC SSLDBA..up_ApplyTemplate;
	END
	IF (@REMOVETEMPLATE = 'Yes') BEGIN
		PRINT 'TEMPLATE UNINSTALL UNDER WAY'
		DECLARE @TempVar VARCHAR(MAX)
		SELECT Name INTO #Alerts FROM msdb..sysalerts WHERE name LIKE 'SSL_%'
		WHILE EXISTS(SELECT * FROM #Alerts) BEGIN
			SET @TempVar = (SELECT TOP(1) name FROM #Alerts)
			EXEC msdb..sp_delete_alert @name = @TempVar;
			PRINT 'Alert ' + @TempVar + ' deleted'
			DELETE TOP(1) FROM #Alerts
		END
	
		SELECT Name INTO #Jobs FROM msdb..sysjobs WHERE name LIKE 'SSL_%'
		WHILE EXISTS(SELECT * FROM #Jobs) BEGIN
			SET @TempVar = (SELECT TOP(1) name FROM #Jobs)
			EXEC msdb..sp_delete_job @job_name = @TempVar;
			PRINT 'Job ' + @TempVar + ' deleted'
			DELETE TOP(1) FROM #Jobs
		END
	
		SELECT * INTO #Messages FROM sys.messages WHERE text Like 'SSL:%'
		WHILE EXISTS(SELECT * FROM #Messages) BEGIN
			SET @TempVar = (SELECT TOP(1) message_id FROM #Messages)
			EXEC msdb..sp_dropmessage  @msgnum = @TempVar;
			SET @TempVar = (SELECT TOP(1) text FROM #Messages)
			PRINT 'Message ' + @TempVar + ' deleted'
			DELETE TOP(1) FROM #Messages
		END

		--DECLARE @FilePath VARCHAR(MAX)
		--DECLARE @files TABLE (FileName VARCHAR(100), Depth INT, FileType INT)
		--SET @FilePath = (SELECT TextValue FROM SSLDBA..tbl_Param WHERE Param = 'SQLDataDumps')
		--DECLARE @cmd NVARCHAR(MAX) = 'xp_DirTree ''' + @FilePath + ''',1,1'
		--INSERT INTO @files EXEC (@cmd) 
		--DELETE FROM @files WHERE FileName NOT LIKE '%SSLDBA%'

		--WHILE EXISTS(SELECT * FROM @files) BEGIN
		--	SET @TempVar = (SELECT TOP(1) FileName FROM @files)
		--	SET @cmd = 'xp_cmdshell ''del "' + @FilePath + '\' + @TempVar + '"''';
		--	EXEC (@cmd)
		--	PRINT 'Backup File ' + @TempVar + ' deleted'
		--	DELETE TOP(1) FROM @files
		--END

		--SET @FilePath = (SELECT TextValue FROM SSLDBA..tbl_Param WHERE Param = 'SQLReportsDir')
		--SET @cmd = 'xp_DirTree ''' + @FilePath + ''',1,1'
		--INSERT INTO @files EXEC (@cmd) 
		--DELETE FROM @files WHERE FileType = 1

		--IF (SELECT FileName FROM @files WHERE FileName NOT IN ('Events', 'DropFolder', 'Dashboard')) = NULL BEGIN
		--	SET @TempVar = N'RMDIR ' + @FilePath + ' /S /Q'
		--	EXEC master..xp_cmdshell @TempVar, no_output
		--	PRINT 'SQL Reports Folder ' + @TempVar + ' deleted'
		--END

		IF ((SELECT TOP(1) name FROM msdb..sysmail_profile WHERE name = 'ManagedSQL') != NULL) BEGIN
			EXEC MSDB..sysmail_delete_profile_sp @profile_name = 'ManagedSQL'
			PRINT 'SQL Services Mail Profile deleted'
		END
		IF ((SELECT TOP(1) name FROM msdb..sysmail_account WHERE name = 'ManagedSQL') != NULL) BEGIN
			EXEC MSDB..sysmail_delete_account_sp @account_name = 'ManagedSQL'
			PRINT 'SQL Services Mail Account deleted'
		END

		--EXEC xp_cmdshell 'del "C:\Windows\pkzipc.exe"'
		--EXEC xp_cmdshell 'del "C:\Windows\elogdmp.exe"'
		--PRINT 'Deleted elogdmp.exe and pkzipc.exe'

		DROP PROCEDURE SSL_SQLStart_Notify;   

		DROP DATABASE SSLDBA
		PRINT 'SSLDBA removed'
		PRINT '-----------------------------------------------'
		PRINT '----------TEMPATE UNINSTALL COMPLETED----------'
		PRINT '-----------------------------------------------'
	END
END
ELSE BEGIN
	PRINT @CONFIRM
END

/*
CHANGE LOG:
V2:
	Added PMF uninstall based on SSLMDW install guide instructions (Q:\Templates\PerformanceFramework\AutomatedPMF\Documentation\01 - SSLMDW Install Guide.docx)
V1:
	Inital build based off document in (Q:\Templates\SLAInstalls\V6\V6.1\Documentation\Removing_DB_FROM_DBA_Template.doc)
*/