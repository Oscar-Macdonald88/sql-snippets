--====================================================================================================
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--Complete steps 1-5 of installation instructions.
--Check for maintenance plans
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--====================================================================================================
 
 
--Configure SP variables
sp_configure 'show advanced options', 1;
GO
RECONFIGURE WITH OVERRIDE
GO
sp_configure 'Database Mail XPs', 1;
GO
sp_configure 'backup compression default', 1
GO
sp_configure 'remote admin connections', 1;
GO
sp_configure 'xp_cmdshell', 1;
GO
sp_configure 'Agent XPs', 1;  
GO  
RECONFIGURE WITH OVERRIDE
GO
sp_configure 'show advanced options', 0
GO
RECONFIGURE WITH OVERRIDE
GO
SELECT name, description, value AS config_value, value_in_USE AS run_value
FROM sys.configurations WHERE name = 'Database Mail XPs' OR name = 'remote admin connections' OR name = 'xp_cmdshell' OR name = 'Agent XPs'
GO 
 
--Create SQLReports
DECLARE @CMD VARCHAR(255) = 'mkdir C:\SQLReports\' + (SELECT @@SERVICENAME) + '\';
EXEC xp_cmdshell @CMD
GO

--Alter Model
ALTER DATABASE model 
    MODIFY FILE
    (NAME = 'modeldev',
	FILEGROWTH = 10%);
GO
 
--Configure Job history
USE [msdb]
GO
EXEC msdb..sp_SET_sqlagent_properties @jobhistory_max_rows=100000, 
		@jobhistory_max_rows_per_job=5000
GO
 
--Create SSLDBA
CREATE DATABASE [SSLDBA]
GO
ALTER DATABASE [SSLDBA] MODIFY FILE
( NAME = SSLDBA, SIZE = 50MB, FILEGROWTH = 10% )  
ALTER DATABASE [SSLDBA] MODIFY FILE
( NAME = SSLDBA_log, SIZE = 10MB, FILEGROWTH = 10% ) ;  
GO  
ALTER DATABASE [SSLDBA] SET RECOVERY SIMPLE;
GO
 
--Configure Mail server
SELECT id, [name] FROM msdb..sysmaintplan_plans;
 
DECLARE @Set_email_address VARCHAR(255) = @@servername + '@a.a' --#########################################
DECLARE @Set_display_name VARCHAR(255) = 'CUSTCode - ' + @@servername + ' (SLALevel)' --#########################################  Gold Silver Bronze Premier Advanced Essentials
 
EXECUTE msdb..sysmail_add_account_sp @account_name = 'ManagedSQL', @description = 'This mail profile is Used by Dimension Data (or SQL Services) to support this SQL Server.', @email_address = @Set_email_address, @replyto_address = 'dba@sqlservices.com', @display_name = @Set_display_name, @port = 25,
	@mailserver_name = 'xxxxxxxxx';--#########################################

DECLARE @profile_id INT, @profile_description sysname;
SELECT @profile_id = COALESCE(MAX(profile_id),1) FROM msdb..sysmail_profile
EXECUTE msdb..sysmail_add_profile_sp @profile_name = 'ManagedSQL', @description = 'This mail profile is Used by Dimension Data (or SQL Services) to support this SQL Server.'
EXECUTE msdb..sysmail_add_profileaccount_sp @profile_name = 'ManagedSQL', @account_name = 'ManagedSQL', @sequence_number = @profile_id;
EXECUTE msdb..sysmail_add_principalprofile_sp @profile_name = 'ManagedSQL', @principal_id = 0, @is_default = 0;
 
SELECT * FROM msdb..sysmail_profile;
SELECT * FROM msdb..sysmail_account;
GO
 
DECLARE @sub VARCHAR(100)
DECLARE @body_text NVARCHAR(MAX)
SELECT @sub = 'Test from New SQL install on ' + @@servername
SELECT @body_text = N'This is a test of Database Mail.' + CHAR(13) + CHAR(13) + 'SQL Server Version Info: ' + CAST(@@version AS VARCHAR(500))
 
EXEC msdb..[sp_send_dbmail] 
    @profile_name = 'ManagedSQL'
  , @recipients = 'Jonathan.Growcott@sqlservices.com'
  , @subject = @sub
  , @body = @body_text
 
EXEC msdb..sp_SET_sqlagent_properties 
	@databasemail_profile = ''
	, @USE_databasemail=1
GO
 
--====================================================================================================
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--!!!!!!!!!!!!!!COPY FILES TO GO ON SERVER!!!!!!!!!!!!!!
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--Run Template install script
--====================================================================================================
USE SSLDBA
EXEC sp_changedbowner 'sa'
--  SET the following default SETting in SSLDBA..tbl_Param
------------------------------------------------------------------------------------------------------
BEGIN Tran
 
/*
UPDATE SSLDBA..tbl_Param SET TextValue = 'Y'
WHERE Param = '24x7'
*/
 
UPDATE SSLDBA..tbl_Param SET TextValue = 'Custcode'
WHERE Param = 'CustCode'
 
UPDATE SSLDBA..tbl_Param SET TextValue = 'CustName'
WHERE Param = 'CustomerName'
 
DECLARE @Domain varchar(100), @key varchar(100)
SET @key = 'SYSTEM\ControlSet001\Services\Tcpip\Parameters\'
EXEC master..xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key=@key,@value_name='Domain',@value=@Domain OUTPUT 
 
UPDATE SSLDBA..tbl_Param SET TextValue = @Domain --<<
WHERE Param = 'DomainName'

UPDATE SSLDBA..tbl_Param SET TextValue = '??' --<< Gold Silver Bronze Premier Advanced Essentials
WHERE Param = 'SLALevel'

UPDATE SSLDBA..tbl_Param SET TextValue = 'CustCode ' + @@SERVERNAME + '(SLALevel)'  --<< Add details AGResearch INVTFSPV03(Bronze)
WHERE Param = 'MailFromName'
 
UPDATE SSLDBA..tbl_Param SET TextValue = 'Y'
WHERE Param = 'CopyDefaultTraceEnabled'
 
UPDATE SSLDBA..tbl_Param	SET TextValue = 'N' --<< WHERE DBMail is configured alongside Kaseya, exclude this if not
WHERE Param = 'LocalMailStaysLocal'
 
UPDATE SSLDBA..tbl_Param SET TextValue = 'C:\SQLReports\' + (SELECT @@SERVICENAME) --<< Add details
WHERE Param = 'CopyDefaultTraceToDir'
 
UPDATE SSLDBA..tbl_Param SET NumValue = 1 --<<!!!!!!UPDATE FROM OTHER INSTANCES!!!!!!
WHERE Param = 'MonthlyJobStartDay'
 
UPDATE SSLDBA..tbl_Param SET NumValue = 190500
WHERE Param = 'DailyBackupStartTime'
 
/*
DECLARE @result TABLE (ID INT IDENTITY(1,1), Output VARCHAR(MAX))
INSERT INTO @result EXEC xp_cmdshell 'SYSTEMINFO'
DELETE FROM @result WHERE Output NOT LIKE '%System Manufacturer%' AND Output NOT LIKE '%System Model%'
UPDATE @result SET Output = REPLACE (Output,'System Manufacturer:','')
UPDATE @result SET Output = REPLACE (Output,'System Model:','')
SELECT ID, RTRIM(LTRIM(Output)) FROM @result
*/
 
UPDATE SSLDBA..tbl_Param SET TextValue = '??' --<< Add details
WHERE Param = 'ServerMake'
 
UPDATE SSLDBA..tbl_Param SET TextValue = '??' --<< Add details
WHERE Param = 'ServerModel'
 
DECLARE @DefaultData NVARCHAR(512)
EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @DefaultData OUTPUT

DECLARE @DefaultLog NVARCHAR(512)
EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', @DefaultLog OUTPUT

DECLARE @DefaultBackup NVARCHAR(512)
EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'BackupDirectory', @DefaultBackup OUTPUT
 
SELECT @DefaultData AS 'Data', @DefaultLog AS 'Log', @DefaultBackup AS 'Backup'

UPDATE SSLDBA..tbl_Param SET TextValue = ISNULL(@DefaultData,CONVERT(NVARCHAR(4000),serverproperty('InstanceDefaultDataPath'))) --<< Add details
WHERE Param = 'SQLData'
 
UPDATE SSLDBA..tbl_Param SET TextValue = @DefaultBackup --<< Add details
WHERE Param = 'SQLDataDumps'
 
UPDATE SSLDBA..tbl_Param SET TextValue = '??'  --<< Add details
WHERE Param = 'SQLLogDumps'
 
UPDATE SSLDBA..tbl_Param SET TextValue = ISNULL(@DefaultLog,CONVERT(NVARCHAR(4000),serverproperty('InstanceDefaultLogPath'))) --<< Add details
WHERE Param = 'SQLLogs'
 
UPDATE SSLDBA..tbl_Param SET TextValue = 'C:\SQLReports\' + (SELECT @@SERVICENAME) + '\' --<< Add details
WHERE Param = 'SQLReportsDir'
 
UPDATE SSLDBA..tbl_Param SET NumValue = 20500
WHERE Param LIKE 'Optimisation%JobStartTime'
 
UPDATE SSLDBA..tbl_Param SET TextValue = 'C:\SQLReports\DropFolder' --<< Add details
WHERE Param = 'DropFolderDir'
 
UPDATE SSLDBA..tbl_Param SET TextValue = 'DBAteam3'	--<<Enter your Team here
WHERE Param = 'SSLTeam'

UPDATE SSLDBA..tbl_Param SET TextValue = 'N'
WHERE Param = 'ReplicationExtension'

-- Now check your changes in SSLDBA..tbl_Param and make any other changes as required
 
 
SELECT TOP (300) 
		Param, NumValue, DateValue, TextValue
	FROM SSLDBA..tbl_Param
	WHERE (TextValue LIKE '%[[]%')
		-- CORE Params (should be picked up by square bracket check if change is required)
		OR Param IN ('ExpectedRows', 'CustCode', 'CustomerName', 'DomainName', 'MailFromName', 'ServerMake', 'ServerModel', 'SSLTeam', 'MonthlyJobStartDay')
		-- Storeage Params
		OR Param IN ('SQLData', 'SQLReportsDir', 'SQLLogDumps', 'SQLLogs', 'SQLDataDumps', 'DropFolderDir') 
		-- Optional Params
		OR Param IN ('AutoApplyTemplate', 'SLALevel', '24x7','IsCluster','IsLogShippingPrimary','IsLogShippingSecondary','IsLSReportingEnabled','IsMirrorMirror','IsMirrorPrincilpal','sMirrorWitness','LogShippingPrimary','PMFInstalled','SSRSMonitorEnabled', 'LocalMailStaysLocal', 'CopyDefaultTraceEnabled' ,'CopyDefaultTraceToDir')
		--Optimise jobs
		OR Param LIKE 'Optimisation%JobStartTime'
COMMIT 
 
---------------------------------------------------------------------------------------------------------------------
--Run UPDATE tbl_Databases script
---------------------------------------------------------------------------------------------------------------------
--Daily OPTIMIZATION
 
INSERT INTO SSLDBA..tbl_DatabasesOptimisationDetail VALUES(1,'%','%','%','%',1)
INSERT INTO SSLDBA..tbl_DatabasesOptimisationDetail VALUES(2,'%','%','%','%',1)
INSERT INTO SSLDBA..tbl_DatabasesOptimisationDetail VALUES(3,'%','%','%','%',1)
INSERT INTO SSLDBA..tbl_DatabasesOptimisationDetail VALUES(4,'%','%','%','%',1)
INSERT INTO SSLDBA..tbl_DatabasesOptimisationDetail VALUES(5,'%','%','%','%',1)
INSERT INTO SSLDBA..tbl_DatabasesOptimisationDetail VALUES(6,'%','%','%','%',1)
INSERT INTO SSLDBA..tbl_DatabasesOptimisationDetail VALUES(7,'%','%','%','%',1)
 
---------------------------------------------------------------------------------------------------------------------
--RUN ONLY IF WE ARE NOT DOING OPTIMIZATION AND/OR BACKUPS
/* 
UPDATE SSLDBA..tbl_Databases SET WeeklyDefrag = 'N', WeeklyDBCC = 'N', UpdateStatistics = 'ALL'
--Where Databasename NOT IN ('SSLDBA', 'SSLMDW')
UPDATE SSLDBA..tbl_Databases SET TemplateBackup = 'N'
--Where Databasename NOT IN ('SSLDBA', 'SSLMDW')
UPDATE SSLDBA..tbl_Databases SET LogBackupStart = NULL
UPDATE SSLDBA..tbl_Databases SET LogBackupFinish = NULL
 
UPDATE SSLDBA..tbl_Databases SET MinPageCount = 1000

--UPDATE SSLDBA..tbl_Databases SET DailyBackupRetention = 2
--UPDATE SSLDBA..tbl_Databases SET LogBackupRetention = 48
*/

---------------------------------------------------------------------------------------------------------------------
--RUN Match disks to partitions script
---------------------------------------------------------------------------------------------------------------------
--Apply Template
EXEC SSLDBA..up_ApplyTemplate;
---------------------------------------------------------------------------------------------------------------------
--Copy files to go on server from SQLReports to Instance folder
DECLARE @CMD VARCHAR(255) = 'for %I in (C:\SQLReports\AppLog_Search.txt C:\SQLReports\DBCC_Search.txt C:\SQLReports\DBCC_SearchExclude.txt C:\SQLReports\SecLog_Search.txt C:\SQLReports\SysLog_Search.txt) do copy %I C:\SQLReports\' + (SELECT @@SERVICENAME) + '\';
EXEC xp_cmdshell @CMD
GO
--Adds line to Servers.txt and creates file if required
DECLARE @CMD VARCHAR(255) = 'IF not EXIST "C:\SQLReports\Servers.txt" type nul>"C:\SQLReports\Servers.txt"'
EXEC xp_cmdshell @CMD
SET @CMD = 'Echo ' + (SELECT TextValue FROM SSLDBA..tbl_Param WHERE Param = 'CustCode') + '	' + (SELECT @@SERVERNAME) + '	' + 'C:\SQLReports\DropFolder\	server=' + (SELECT @@SERVERNAME) + ';Trusted_Connection=true;database=SSLDBA;>>C:\SQLReports\Servers.txt'
EXEC xp_cmdshell @CMD
GO
---------------------------------------------------------------------------------------------------------------------
--SELECT * FROM SSLDBA..tbl_Operator
UPDATE SSLDBA..tbl_Operator SET [EMailAddress] = 'dba_info3@sqlservices.com' WHERE Operator = 'In-House DBA'
---------------------------------------------------------------------------------------------------------------------
 
--SET duration alarms and run jobs
USE [SSLDBA]
GO
	EXEC msdb..sp_start_job N'SSL_CheckLongRunningJobs';
	WAITFOR DELAY '00:00:05'
 
	UPDATE SSLDBA..tbl_JobHistDetails
	SET Auto_stop='Y',
		Duration_alarm=CASE Job_name 
			WHEN 'SSL_Weekly_Job' THEN 600 
			WHEN 'SSL_Monthly_Report' THEN 200 
			WHEN 'SSL_SendDashboardData' THEN 7 
			WHEN 'SSL_Optimise_GenMasterList' THEN 60 
		END
	WHERE Job_name IN ('SSL_Weekly_Job', 'SSL_Monthly_Report', 'SSL_SendDashboardData',
						'SSL_Optimise_GenMasterList')
 
	UPDATE SSLDBA..tbl_JobHistDetails SET Duration_alarm=300, Auto_stop='Y' WHERE Job_name LIKE 'SSL_Optimise_[^G]%'
	UPDATE SSLDBA..tbl_JobHistDetails SET Duration_alarm=600, Auto_stop='Y' WHERE Job_name = 'SSL_Optimise_Sunday'
	
	UPDATE SSLDBA..tbl_JobHistDetails SET Duration_alarm=180 WHERE Job_name = 'SSL_Backup_All_Databases'
	
	SELECT * FROM SSLDBA..tbl_JobHistDetails WHERE Job_name LIKE 'SSL_%' ORDER BY Job_name
GO
 
msdb..sp_start_job N'SSL_Backup_All_Databases';
GO
msdb..sp_start_job N'SSL_Weekly_Job', @step_name='Run SSL Health Check Script';
GO
msdb..sp_start_job N'SSL_CheckDiskSpace';
GO
msdb..sp_start_job N'SSL_CheckLongRunningJobs';
GO
msdb..sp_start_job N'SSL_SendDBCCFileWeekly';
GO
msdb..sp_start_job N'SSL_CheckBlocking';
GO
msdb..sp_start_job N'SSL_DailyChecks';
GO
msdb..sp_start_job N'SSL_Monthly_Report';
GO
msdb..sp_start_job N'SSL_SendDashboardData';
GO
SELECT sj.name, sja.run_requested_date, CONVERT(VARCHAR(12), sja.stop_execution_date-sja.start_execution_date, 114) Duration FROM msdb..sysjobactivity sja INNER JOIN msdb..sysjobs sj ON sja.job_id = sj.job_id WHERE sja.run_requested_date IS NOT NULL ORDER BY sja.run_requested_date desc;
GO
 
EXEC msdb..sp_UPDATE_job @job_name='SSL_Weekly_Job',@enabled = 1
EXEC msdb..sp_UPDATE_job @job_name='SSL_Monthly_Report',@enabled = 1
EXEC msdb..sp_UPDATE_job @job_name='SSL_SendDashboardData',@enabled = 1
EXEC msdb..sp_UPDATE_job @job_name='SSL_CheckDBSpace',@enabled = 0
GO

--generate disable
--SELECT 'exec msdb..sp_update_job @job_name = '''+NAME+''', @enabled = 0' FROM msdb..sysjobs
--generate enable
--SELECT 'exec msdb..sp_update_job @job_name = '''+NAME+''', @enabled = 1' FROM msdb..sysjobs