--Preinstall Checks
SELECT convert(varchar, (SERVERPROPERTY('Servername'))) AS 'ServerName'
SELECT '!!!!!CHECK IF 2016!!!!!' AS '!!!!!CHECK IF 2016!!!!!', @@VERSION AS 'Version'
 
DECLARE @CMD VARCHAR(255) = 'mkdir C:\SQLPMF\' + (SELECT @@SERVICENAME) + '\';
EXEC xp_cmdshell @CMD
GO
 
--CREATE SSLMDW
CREATE DATABASE [SSLMDW];
GO
ALTER DATABASE [SSLMDW] MODIFY FILE
( NAME = SSLMDW, SIZE = 100MB, FILEGROWTH = 100MB )
ALTER DATABASE [SSLMDW] MODIFY FILE
( NAME = SSLMDW_log, SIZE = 10MB, FILEGROWTH = 10MB ) ;
GO
ALTER DATABASE [SSLMDW] SET RECOVERY SIMPLE;
GO
USE SSLMDW
EXEC sp_changedbowner 'sa'
USE master
 
--====================================================================================================
--SETUP DATA COLLECTION AND DATAWAREHOUSE
--====================================================================================================
 
--Stop collection SETs
 
use msdb;
go
 
declare @SystemCollectorID int;
 
while exists(select [collection_set_id] from [syscollector_collection_sets] where [is_running] = 1 and [is_system] = 1) begin
	set @SystemCollectorID = (select top(1) [collection_set_id] from [syscollector_collection_sets] where [is_running] = 1 and [is_system] = 1);
 
	exec [sp_syscollector_stop_collection_set] @collection_set_id = @SystemCollectorID;
end
 
select * from [syscollector_collection_sets]
 
--====================================================================================================
--INSTALL THE PMF
--====================================================================================================
 
--Configure PMF
USE [SSLMDW];
GO
 
UPDATE pmf.tbl_Param
SET TextValue = (SELECT TextValue FROM SSLDBA..tbl_Param WHERE Param = 'CustCode')
WHERE Param = 'CustCode';
 
UPDATE pmf.tbl_Param
SET TextValue = (SELECT TextValue FROM SSLDBA..tbl_Param WHERE Param = 'SSLTeam')
WHERE Param = 'SSLTeam';
 
UPDATE pmf.tbl_Param
SET TextValue = (SELECT EMailAddress FROM SSLDBA..tbl_Operator WHERE Operator = 'SQL Services Gold')
WHERE Param = 'SSLTeamEmail';
 
UPDATE pmf.tbl_Param
SET TextValue = (SELECT TextValue FROM SSLDBA..tbl_Param WHERE Param = 'DropFolderDir')
WHERE Param = 'DropFolderDir';
 
UPDATE pmf.tbl_Param
SET TextValue = 'C:\SQLPMF\' + (SELECT @@SERVICENAME) + '\'
WHERE Param = 'PMFDir';
 
 
USE SSLMDW
GO
EXEC SSLMDW.pmf.up_ApplyPMF
GO
 
EXEC SSLDBA..up_ApplyTemplate
 
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'mdw_purge_data_[SSLMDW]', @owner_login_name=N'sa'
EXEC msdb.dbo.sp_update_job @job_name=N'sysutility_get_cache_tables_data_into_aggregate_tables_daily', @owner_login_name=N'sa'
EXEC msdb.dbo.sp_update_job @job_name=N'sysutility_get_cache_tables_data_into_aggregate_tables_hourly', @owner_login_name=N'sa'
EXEC msdb.dbo.sp_update_job @job_name=N'sysutility_get_views_data_into_cache_tables', @owner_login_name=N'sa'
GO
 
SELECT 'EXEC msdb..sp_update_job @job_name= N''' + ([name]) + ',@enabled = 0''' AS 'Disable System Datacollector jobs' FROM msdb.dbo.sysjobs WHERE enabled = 1 AND name LIKE 'collection_set_%'
 
declare
	@uploadjob nvarchar(255) = 'msdb..sp_start_job N''' + (select [name] from [msdb].[dbo].[sysjobs] where [enabled] = 1 and [name] like 'SSL_%collection_set_%_upload') + '''';
print @uploadjob
exec [sp_executesql] @uploadjob;
GO
WAITFOR DELAY '00:00:10';
GO
msdb..sp_start_job N'SSL_PMF_ExtractData';
GO
 
/*
UPDATE SSLDBA..tbl_Databases SET WeeklyDefrag = 'N', WeeklyDBCC = 'N', UpdateStatistics = 'ALL', MinPageCount = 1000 Where DatabaseName = 'SSLMDW'
*/