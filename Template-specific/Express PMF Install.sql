--====================================================================================================
-- README!
-- This script is intended to be run in sections.
-- While installing this script, pay attention to the large titled comments.
-- These are extra steps that require you to follow the standard PMF install instructions:
-- SETUP DATA COLLECTION AND DATAWAREHOUSE
-- INSTALL THE PMF
--
-- Run the script in blocks, separated by the extra steps.
--====================================================================================================

--Preinstall Checks
SELECT @@ServerName AS 'ServerName'
SELECT '!!!!!CHECK IF 2016!!!!!' AS '!!!!!CHECK IF 2016!!!!!', @@VERSION AS 'Version'
EXEC xp_cmdshell 'mkdir C:\SQLPMF';
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
USE msdb;
GO
DECLARE @idX INT;
DECLARE cSET CURSOR FOR
SELECT collection_SET_id FROM syscollector_collection_SETs;
OPEN cSET
FETCH NEXT FROM cSET INTO @idX;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC sp_syscollector_stop_collection_SET @collection_SET_id = @idX;
    FETCH NEXT FROM cSET INTO @idX;
END
CLOSE cSET
DEALLOCATE cSET
GO
--====================================================================================================
--INSTALL THE PMF
--====================================================================================================
--Configure PMF
USE [SSLMDW];
GO

UPDATE ssl.parameter
SET TextValue = (SELECT textvalue FROM SSLDBA..tbl_Param WHERE Param = 'CustCode')
WHERE ParamName = 'CustCode';
UPDATE ssl.parameter
SET TextValue = (SELECT textvalue FROM SSLDBA..tbl_Param WHERE Param = 'SSLTeam')
WHERE ParamName = 'SSLTeam';
UPDATE ssl.parameter
SET TextValue = (SELECT EMailAddress FROM SSLDBA..tbl_Operator WHERE Operator = 'SQL Services Gold')
WHERE ParamName = 'SSLTeamEmail';
UPDATE ssl.parameter
SET TextValue = (SELECT textvalue FROM SSLDBA..tbl_Param WHERE Param = 'DropFolderDir')
WHERE ParamName = 'DropFolderDir';
UPDATE ssl.parameter
SET TextValue = 'C:\SQLPMF\'
WHERE ParamName = 'PMFDir';

USE SSLMDW
GO
EXEC SSLMDW.SSL.UP_APPLYPMF

GO
--ApplyTemplate (Add to tblDB if need be)
EXEC SSLDBA..up_ApplyTemplate
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'mdw_purge_data_[SSLMDW]', @owner_login_name=N'sa'
EXEC msdb.dbo.sp_update_job @job_name=N'sysutility_get_cache_tables_data_into_aggregate_tables_daily', @owner_login_name=N'sa'
EXEC msdb.dbo.sp_update_job @job_name=N'sysutility_get_cache_tables_data_into_aggregate_tables_hourly', @owner_login_name=N'sa'
EXEC msdb.dbo.sp_update_job @job_name=N'sysutility_get_views_data_into_cache_tables', @owner_login_name=N'sa'
GO
DECLARE @uploadjob NVARCHAR(255) = 'msdb..sp_start_job N''' + (SELECT [name] FROM msdb.dbo.sysjobs WHERE enabled = 1 AND name LIKE 'SSL_collection_set_%_upload') + ''''
EXEC sp_executesql @uploadjob;
GO
WAITFOR DELAY '00:00:10';
GO
msdb..sp_start_job N'SSL_PMF_ExtractData';
GO