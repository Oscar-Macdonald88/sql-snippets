---- WARNING: Use of the database addition generated scripts will provide a basic ground work, but should reviewed as it will 'mostly' just go with defaults
DECLARE @SSL_helpDB TABLE ([name] VARCHAR(200), [size] VARCHAR(20), [owner] VARCHAR(50), [dbid] INT, [created] DATETIME, [status] VARCHAR(4000), [compat] INT);
INSERT @SSL_helpDB EXEC sp_helpdb;

SELECT ISNULL(helpDB.name, newDBs.name) AS 'Databases to Add', helpDB.size, newDBs.recovery_model_desc AS [model], helpDB.owner,
'INSERT INTO SSLDBA.dbo.tbl_Databases (DatabaseName, DailyBackup, TemplateBackup, DailyBackupType, WeeklyDBCC, WeeklyDefrag, LogBackupStart, LogBackupFinish, DailyBackupRetention, UpdateModifiedStatistics, OptimisePostCheck,  Status) VALUES ('''+helpDB.name+''', ''' + (SELECT TOP 1 DailyBackup FROM SSLDBA.dbo.tbl_Databases WHERE Type = 'OLTP') + ''', ''' + (SELECT TOP 1 TemplateBackup FROM SSLDBA.dbo.tbl_Databases WHERE Type = 'OLTP') + ''', ''F'', ''' + (SELECT TOP 1 WeeklyDBCC FROM SSLDBA.dbo.tbl_Databases WHERE Type = 'OLTP') + ''', ''' + (SELECT TOP 1 WeeklyDefrag FROM SSLDBA.dbo.tbl_Databases WHERE Type = 'OLTP') + ''', ' + CASE newDBs.recovery_model_desc WHEN 'FULL' THEN (CASE (SELECT TOP 1 LogBackupFinish FROM SSLDBA..tbl_Databases WHERE Status LIKE '%Recovery=FULL%') WHEN '235959' THEN ' 0, 235959' ELSE 'NULL, NULL' END) ELSE 'NULL, NULL' END + ', ' + CONVERT(VARCHAR(10), (SELECT TOP 1 DailyBackupRetention FROM SSLDBA.dbo.tbl_Databases WHERE Type = 'OLTP')) + ', ''' + (SELECT TOP 1 UpdateModifiedStatistics FROM SSLDBA.dbo.tbl_Databases WHERE Type = 'OLTP') + ''', ''' + (SELECT TOP 1 OptimisePostCheck FROM SSLDBA.dbo.tbl_Databases WHERE Type = 'OLTP') + ''', ''' + helpDB.status + ''');' AS [T-SQL_Add], 
'INSERT INTO SSLDBA.dbo.tbl_Databases (DatabaseName) VALUES (''' +helpDB.name+ ''')' AS [T-SQL_ALL_Default_Add],
(CASE (SELECT TOP 1 TemplateBackup FROM SSLDBA.dbo.tbl_Databases WHERE Type = 'OLTP') WHEN 'N' THEN 'No Backup' ELSE ('EXEC SSLDBA.dbo.up_BackupDatabase '''+helpDB.name+'''' + '; ' + CASE newDBs.recovery_model_desc WHEN 'FULL' THEN 'EXEC msdb.dbo.sp_start_job @Job_Name = ''SSL_Backup_Log_' + helpDB.name + '''' ELSE '' END + '')END) AS [T-SQL_Backup]
FROM sys.databases newDBs LEFT JOIN @SSL_helpDB helpDB ON helpDB.name = newDBs.name CROSS JOIN (SELECT TextValue FROM SSLDBA.dbo.tbl_Param WHERE Param='TemplateVersion') templateVersion WHERE newDBs.name NOT IN (SELECT DatabaseName FROM SSLDBA.dbo.tbl_Databases);
SELECT tdb.DatabaseName, 'UPDATE SSLDBA.dbo.tbl_Databases SET DailyBackup=''N'', TemplateBackup=''N'', LogBackupStart=NULL, LogBackupFinish=NULL, WeeklyDBCC=''N'', WeeklyDefrag=''N'', ReportSpaceUsed=''N'' WHERE DatabaseName='''+name+'''' AS [Update_T-SQL] FROM sys.databases sdb LEFT JOIN SSLDBA.dbo.tbl_Databases tdb ON (sdb.name=tdb.DatabaseName) WHERE state_desc='OFFLINE' AND 'Y' IN (tdb.DailyBackup, tdb.TemplateBackup, tdb.WeeklyDBCC, tdb.WeeklyDefrag, tdb.ReportSpaceUsed) ORDER BY name;
SELECT DatabaseName AS 'Databases to Delete', 'Delete FROM SSLDBA..tbl_Databases WHERE DatabaseName = ''' + DatabaseName + ''';' AS 'Databases to delete' FROM SSLDBA..tbl_Databases WHERE DatabaseName not in (SELECT name FROM sys.databases);
SELECT sys.databases.name, size, state_desc, recovery_model_desc, DailyBackup, TemplateBackup, DailyBackupType, LogBackupStart, (CASE (SELECT TemplateBackup FROM SSLDBA..tbl_Databases WHERE DatabaseName = sys.databases.name) WHEN 'N' THEN 'No Backup' ELSE ('EXEC SSLDBA.dbo.up_BackupDatabase '''+helpDB.name+'''' + '; ' + CASE recovery_model_desc WHEN 'FULL' THEN 'EXEC msdb.dbo.sp_start_job @Job_Name = ''SSL_Backup_Log_' + helpDB.name + '''' ELSE '' END + '' )END) AS [T-SQL_Backup] FROM sys.databases LEFT JOIN @SSL_helpDB helpDB ON helpDB.name = sys.databases.name INNER JOIN SSLDBA..tbl_Databases ON sys.databases.name=DatabaseName ORDER BY recovery_model_desc DESC;

/*
1) ADD/REMOVE DB 2) Apply Template 3) RUN Weekly job 4) Backup Databases

SELECT * FROM SSLDBA..tbl_Databases ORDER BY DatabaseName ASC;

EXEC SSLDBA..up_ApplyTemplate;

EXEC msdb.dbo.sp_start_job N'SSL_Weekly_Job', @step_name='Run SSL Health Check Script';
GO
WAITFOR DELAY '00:00:05'; 
GO
SELECT DISTINCT TOP(50) sj.name, sja.run_requested_date, CONVERT(VARCHAR(12), sja.stop_execution_date-sja.start_execution_date, 114) Duration, case sjh.run_status when 0 then 'Failed' when 1 then 'Successful' when 3 then 'Cancelled' when 4 then 'In Progress' end as JobStatus FROM msdb.dbo.sysjobactivity sja INNER JOIN msdb.dbo.sysjobs sj ON sja.job_id = sj.job_id LEFT JOIN msdb.dbo.sysjobHistory sjh ON sj.job_id = sjh.job_id WHERE sja.run_requested_date IS NOT NULL ORDER BY sja.run_requested_date desc;
GO






GO





*/
