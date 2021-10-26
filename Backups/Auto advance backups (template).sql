/*
DECLARE @HDB TABLE (dbname VARCHAR(200), size VARCHAR(20), owner VARCHAR(50), dbid INT, created DATETIME, status VARCHAR(4000), compat INT); INSERT @HDB EXEC sp_helpdb;
SELECT '''' + dbname + ''',' AS dbname, size, DailyBackupType FROM @HDB HDB INNER JOIN SSLDBA..tbl_Databases TDB ON HDB.dbname = TDB.DatabaseName ORDER BY DailyBackupType DESC ,size DESC
GO
*/
-- run above first


SET NOCOUNT ON 
SELECT * INTO #TDB FROM SSLDBA..tbl_Databases WHERE DailyBackup != 'N' AND TemplateBackup != 'N' AND DatabaseName IN 
() -- copy from above result, remove the last comma and paste here

DECLARE @StartTime INT 
SET @StartTime = 210000
WHILE EXISTS (SELECT * FROM #TDB) BEGIN
            UPDATE SSLDBA..tbl_Databases SET DailyBackupType = 'A' WHERE DatabaseName = (SELECT TOP(1) DatabaseName FROM #TDB)
            INSERT INTO SSLDBA..tbl_DatabaseBackups (DatabaseName, TemplateBackup, BackupType, Freq_Type, Freq_Interval, Freq_SubType, StartTime, FinishTime, BackupRetention, BackupFileNameMask) 
            VALUES ((SELECT TOP(1) DatabaseName FROM #TDB), 'Y', 'F', 'D', 1, 'N', @StartTime, 235959, (SELECT TOP(1) DailyBackupRetention FROM #TDB), '{DBName}_{TYPE:FULL|DIFF}_{DATE:YYYYMMDD}.dat')
            DELETE TOP(1) FROM #TDB
            SET @StartTime = @StartTime + 500
            IF @StartTime > 235959 BEGIN
                        SET @StartTime = 000000
            END
END

SELECT * FROM SSLDBA..tbl_Databases
SELECT * FROM SSLDBA..tbl_DatabaseBackups

DROP TABLE #TDB

EXEC SSLDBA..up_ApplyTemplate;

EXEC msdb..sp_start_job N'SSL_CheckLongRunningJobs';
GO

WAITFOR DELAY '00:00:10'; 
UPDATE SSLDBA..tbl_JobHistDetails SET Duration_alarm = (SELECT Duration_alarm FROM SSLDBA..tbl_JobHistDetails WHERE Job_name = 'SSL_Backup_All_Databases') WHERE Job_name LIKE 'SSL_Backup_Full_%'
SELECT * FROM SSLDBA..tbl_JobHistDetails WHERE Job_name LIKE 'SSL_Backup_Full_%'
