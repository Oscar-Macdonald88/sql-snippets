BEGIN TRY
	BEGIN TRAN
	DECLARE @READMODE VARCHAR(20) = 'READONLY' -- READWRITE READONLY
	DECLARE @Components VARCHAR(20) = 'AdUpOfOnDeRe' -- AdUpOfOnDeRe
	DECLARE @ForceOverWrite VARCHAR(20) = 'MATCH' -- GLOBAL FORCE MATCH
	DECLARE @ForceMatchDB VARCHAR(50) = '%%' --DB Name Here
	DECLARE @SingleDB VARCHAR(50) = '%%' --DB Name Here
	DECLARE @ExcludeDB VARCHAR(50) = '' --DB Name Here
	DECLARE @AutoApplyTemplate VARCHAR(20) = 'APPLY' -- MANUAL APPLY
/*
Jonathan's Mostly Automated tbl_Databases updater
WARNING: Use of this script will provide a 'Best-Guess' based of other entries in TBL_Databases. !!!!!!!!!!!PLEASE REVIEW ALL ADDITIONS!!!!!!!!!!!
 
1)Run whole script in READONLY 2)Check Variables above 3)Run whole script in READWRITE 4)Apply Template and Weekly job 5)Backup Databases
EXEC SSLDBA..up_ApplyTemplate;
EXEC msdb..sp_start_job N'SSL_Weekly_Job', @step_name='Run SSL Health Check Script';
GO
 
 
 
 
 
GO
*/
	SELECT * INTO #TDB FROM SSLDBA..tbl_Databases WHERE Type = 'OLTP' AND DatabaseName LIKE @SingleDB AND DatabaseName NOT LIKE @ExcludeDB
	DECLARE @HDB TABLE (dbname VARCHAR(200), size VARCHAR(20), owner VARCHAR(50), dbid INT, created DATETIME, status VARCHAR(4000), compat INT); INSERT @HDB EXEC sp_helpdb;
	SELECT *, ('EXEC SSLDBA..up_BackupDatabase @DatabaseName = '''+ [name] +'''' + ', @Stats = 5; ' + CASE WHEN (recovery_model_desc = 'FULL') AND (SELECT primary_database FROM msdb..log_shipping_primary_databases WHERE primary_database = [name]) IS NULL THEN 'EXEC msdb..sp_start_job @Job_Name = ''SSL_Backup_Log_' + [name] + '''' ELSE '' END + '' + '  --  ' + [name] + '   ' + (SELECT RTRIM(LTRIM(size)) FROM @HDB a WHERE [name] = dbname) + ' ' + CASE WHEN ((SELECT AltBackupLocation FROM #TDB WHERE DatabaseName = [name]) IS NOT NULL) THEN '!!!ALT LOCATION WARNING!!! UPDATE SSLDBA..tbl_Databases SET AltBackupLocation = ''' + (SELECT TOP(1) AltBackupLocation FROM #TDB WHERE DatabaseName = [name]) + ''' WHERE DatabaseName = ''' + [name] + '''; ' ELSE '' END) AS 'BackupScript' INTO #TSDB FROM sys.databases
	SELECT * INTO #SDB FROM #TSDB LEFT JOIN @HDB ON dbname = [name]
	SELECT TOP(1)  #TDB.* INTO #SSL_tempDB FROM #TDB INNER JOIN #SDB ON #TDB.DatabaseName = #SDB.[name] WHERE DatabaseName LIKE @ForceMatchDB AND state_desc NOT IN ('OFFLINE', 'RESTORING') ORDER BY DatabaseName;
	DECLARE @GlobalMatch VARCHAR(255) = (SELECT DatabaseName COLLATE Latin1_General_CI_AI FROM #SSL_tempDB)
	IF @ForceOverWrite = 'FORCE'BEGIN
		UPDATE #SSL_tempDB SET DailyBackup = 'N', TemplateBackup = 'N', WeeklyDBCC = 'N', WeeklyDefrag = 'N', LogBackupStart = NULL, LogBackupFinish = NULL;
	END
	IF EXISTS(SELECT * FROM #TDB WHERE DailyBackupType = 'A')BEGIN SELECT 'Advanced backup detected. Please review' AS 'WARNING', 'SELECT * FROM SSLDBA..tbl_DatabaseBackups' AS 'TSQL' END
	--------------------------- Readonly Selects ---------------------------
	SELECT * INTO #TempUpdates FROM(SELECT @READMODE + ': ' + @ForceOverWrite + ' ' + @SingleDB + ' ' + @ExcludeDB AS 'Action', @@SERVERNAME AS 'Name', '--' AS 'Size' , '--' AS 'Recovery', 'Fallback: ' + @GlobalMatch AS 'Match', '--' AS 'Owner', '--' AS 'T-SQL_Backup', '--' AS 'Connectwise entry' UNION ALL	
	SELECT 'ADD', #SDB.[name], RTRIM(LTRIM(#SDB.size)), #SDB.recovery_model_desc, (CASE @ForceOverWrite WHEN 'MATCH' THEN 'No Direct match found' ELSE 'Direct matching disabled' END), #SDB.owner, (CASE (SELECT TOP 1 TemplateBackup FROM #SSL_tempDB WHERE Type = 'OLTP') WHEN 'N' THEN '--No Backup' ELSE (#SDB.BackupScript)END), 'Database '+CONVERT(VARCHAR, #SDB.[name])+' Added to template,       Recovery: '+ISNULL(CAST (#SDB.recovery_model_desc AS VARCHAR) COLLATE SQL_Latin1_General_CP1_CI_AS,'') FROM #SDB WHERE #SDB.[name] NOT IN (SELECT DatabaseName FROM SSLDBA..tbl_Databases) AND @Components LIKE '%Ad%' UNION ALL
	SELECT state_desc/*RECON*/,  #TDB.DatabaseName, '', #SDB.recovery_model_desc, '', '', '', 'Database ' + #SDB.[name] + ' is ' + #SDB.state_desc + '. Configured as Offline in template' FROM #SDB LEFT JOIN  #TDB ON (#SDB.[name]= #TDB.DatabaseName) WHERE (state_desc='OFFLINE' OR state_desc='RESTORING') AND ( #TDB.DailyBackup = 'Y' OR  #TDB.TemplateBackup = 'Y' OR  #TDB.WeeklyDBCC = 'Y' OR  #TDB.WeeklyDefrag = 'Y' OR  #TDB.ReportSpaceUsed = 'Y' OR  #TDB.LogBackupStart IS NOT NULL OR  #TDB.LogBackupFinish IS NOT NULL) AND @Components LIKE '%Of%' UNION ALL
	SELECT state_desc/*OFF/ON*/, DatabaseName, '', #SDB.recovery_model_desc, '', '', '', 'Database ' + DatabaseName + ' set Online in template' FROM #SDB LEFT JOIN  #TDB ON #SDB.[name] =  #TDB.DatabaseName WHERE #TDB.status LIKE '%OFFLINE%' AND state_desc='ONLINE' AND @Components LIKE '%On%' UNION ALL
	SELECT 'DELETE', DatabaseName, '', '', '', '', '', 'Database ' + DatabaseName + ' Removed from template' FROM  #TDB WHERE  #TDB.DatabaseName NOT IN (SELECT [name] FROM #SDB) AND @Components LIKE '%De%' UNION ALL
	SELECT 'RECONFIGURE',  #TDB.DatabaseName, '', #SDB.recovery_model_desc, '', suser_sname(#SDB.owner_sid), #SDB.BackupScript, 'Database ' +  #TDB.DatabaseName + ' reconfigured for use in ' + CASE WHEN #TDB.DatabaseName IN (SELECT primary_database FROM msdb..log_shipping_primary_databases) THEN 'LogShipping' ELSE #SDB.recovery_model_desc END FROM #TDB INNER JOIN #SDB ON  #TDB.DatabaseName = #SDB.[name] WHERE (DailyBackup = 'Y' AND TemplateBackup = 'Y') AND ((#SDB.recovery_model_desc = 'SIMPLE' AND  #TDB.LogBackupStart IS NOT NULL) OR (#SDB.recovery_model_desc != 'SIMPLE' AND #SDB.is_read_only = 0 AND (#TDB.LogBackupStart IS NULL AND ((SELECT primary_database FROM msdb..log_shipping_primary_databases WHERE primary_database =  #TDB.DatabaseName) IS NULL)) OR (#TDB.LogBackupStart IS NOT NULL AND ((SELECT primary_database FROM msdb..log_shipping_primary_databases WHERE primary_database =  #TDB.DatabaseName) IS NOT NULL))) AND #SDB.state_desc = 'ONLINE' AND @Components LIKE '%Re%'))i
	--------------------------- Matching System ---------------------------
	IF (@ForceOverWrite = 'MATCH' AND @ForceMatchDB = '%%') BEGIN
		SELECT * INTO #MatchDBs FROM #TempUpdates WHERE Action IN ('ADD', 'ONLINE', 'RECONFIGURE')
		DECLARE @MatchDB VARCHAR(255)
		DECLARE @DBToMatch VARCHAR(255)
		WHILE EXISTS (SELECT * FROM #MatchDBs) BEGIN
			SET @DBToMatch = (SELECT TOP(1) [name] FROM #MatchDBs)
			SET @SingleDB = @DBToMatch
			WHILE ((LEN(@SingleDB) > 3) AND @MatchDB IS NULL) BEGIN
				SET @MatchDB = (SELECT TOP(1) DatabaseName FROM  #TDB WHERE Type = 'OLTP' AND DatabaseName LIKE @SingleDB + '%' AND DatabaseName != @DBToMatch)
				IF (@MatchDB IS NOT NULL) BEGIN
					UPDATE #TempUpdates SET Match = @MatchDB WHERE Name = @DBToMatch
					INSERT INTO #SSL_tempDB SELECT TOP(1) * FROM #TDB WHERE DatabaseName = @MatchDB
					UPDATE TOP(1) #SSL_tempDB SET DatabaseName = @DBToMatch WHERE DatabaseName = @MatchDB
					BREAK
				END
				SET @SingleDB = LEFT(@SingleDB, LEN(@SingleDB) - 1)
			END
			IF (@MatchDB IS NULL) BEGIN
				DELETE FROM #SSL_tempDB WHERE DatabaseName = @GlobalMatch
				INSERT INTO #SSL_tempDB SELECT TOP(1) * FROM #TDB WHERE DatabaseName = @GlobalMatch
				UPDATE #SSL_tempDB SET DatabaseName = @DBToMatch WHERE DatabaseName = @GlobalMatch
			END
			SET @MatchDB = NULL
			DELETE TOP(1) FROM #MatchDBs
		END
		DROP TABLE #MatchDBs;
	END
	SELECT * FROM #TempUpdates
	--------------------------- Read/Write Systems ---------------------------
	IF (@READMODE = 'READWRITE' AND (SELECT COUNT(*) FROM #TempUpdates) > 1) BEGIN
		--DELETE FROM SSLDBA..tbl_Databases_AlwaysOn_Support WHERE DatabaseName IN (SELECT [name] FROM #TempUpdates WHERE Action IN ('DELETE', 'ONLINE', 'RECONFIGURE'))
		DELETE FROM SSLDBA..tbl_Databases WHERE DatabaseName IN (SELECT [name] FROM #TempUpdates WHERE Action IN ('DELETE', 'ONLINE', 'RECONFIGURE'))
		UPDATE #TempUpdates SET Action = 'ADD' WHERE Action IN ('ONLINE', 'RECONFIGURE')
		DECLARE @Name VARCHAR(255)
		WHILE EXISTS(SELECT * FROM #TempUpdates WHERE Action = 'ADD') BEGIN
			SET @Name = (SELECT TOP(1) #SDB.[name] FROM #SDB INNER JOIN #TempUpdates tud ON tud.Name = #SDB.[name] WHERE #SDB.[name] NOT IN (SELECT DatabaseName FROM SSLDBA..tbl_Databases) AND Action != 'OFFLINECHECK')
			IF (SELECT COUNT(*) FROM #tdb) = 0 BEGIN
				INSERT INTO SSLDBA..tbl_Databases (DatabaseName) VALUES (@Name)
			END
			ELSE IF (SELECT COUNT(*) FROM #SSL_tempDB WHERE DatabaseName = @Name) = 1 BEGIN
				UPDATE #SSL_tempDB SET Status = #SDB.status, LogBackupStart = CASE #SDB.recovery_model_desc WHEN 'FULL' THEN (CASE WHEN (SELECT TemplateBackup FROM #SSL_tempDB WHERE DatabaseName = @Name) = 'Y' AND (SELECT DailyBackup FROM #SSL_tempDB WHERE DatabaseName = @Name) = 'Y' AND (SELECT COUNT(*) FROM msdb..log_shipping_primary_databases WHERE primary_database =  @Name) = 0 THEN 0 ELSE NULL END) ELSE NULL END, LogBackupFinish = CASE #SDB.recovery_model_desc WHEN 'FULL' THEN (CASE WHEN ((SELECT TemplateBackup FROM #SSL_tempDB WHERE DatabaseName = @Name) = 'Y' AND (SELECT DailyBackup FROM #SSL_tempDB WHERE DatabaseName = @Name) = 'Y' AND (SELECT COUNT(*) FROM msdb..log_shipping_primary_databases WHERE primary_database =  @Name) = 0) THEN 235959 ELSE NULL END) ELSE NULL END FROM #SDB WHERE #SDB.[name] = @Name;
				INSERT INTO SSLDBA..tbl_Databases SELECT * FROM #SSL_tempDB WHERE DatabaseName = @Name
			END
			ELSE IF (SELECT COUNT(*) FROM #SSL_tempDB) = 1 BEGIN
				UPDATE #SSL_tempDB SET DatabaseName = @Name
				INSERT INTO SSLDBA..tbl_Databases SELECT * FROM #SSL_tempDB
			END
			UPDATE TOP(1) #TempUpdates SET Action = 'OFFLINECHECK' WHERE Action = 'ADD'
		END
		UPDATE SSLDBA..tbl_Databases SET DailyBackup='N', TemplateBackup='N', LogBackupStart= NULL, LogBackupFinish= NULL, WeeklyDBCC='N', WeeklyDefrag='N', ReportSpaceUsed= 'N' WHERE (SELECT is_read_only FROM #SDB WHERE [Name] = DatabaseName) = 1 OR DatabaseName IN (SELECT [Name] FROM #TempUpdates WHERE Action IN ('OFFLINE', 'RESTORING') OR (Action = 'OFFLINECHECK' AND Name IN (SELECT [Name] FROM #SDB WHERE state_desc IN ('OFFLINE', 'RESTORING'))))
		IF (@AutoApplyTemplate = 'APPLY') BEGIN SET @AutoApplyTemplate = 'RUNAPPLY' END
	END
    --------------------------- Final Select ---------------------------
	SELECT #SDB.[name] AS 'Name', size AS 'Size', state_desc AS 'State', recovery_model_desc AS 'Recovery', DailyBackup, TemplateBackup, DailyBackupType, (CASE LogBackupStart WHEN NULL THEN 'Off' ELSE 'On ' + CONVERT(VARCHAR,LogBackupStart) END) AS 'Log backups', 'UPDATE SSLDBA..tbl_Databases SET DailyBackup = ''' + DailyBackup + ''', TemplateBackup = ''' + TemplateBackup + ''' WHERE DatabaseName = ''' + #SDB.[name] + '''' AS 'Backup Status', (CASE (SELECT TemplateBackup FROM SSLDBA..tbl_Databases WHERE DatabaseName = #SDB.[name]) WHEN 'N' THEN 'No Backup' ELSE (#SDB.BackupScript)END) AS 'T-SQL_Backup', '---------------------->' AS 'TBLDatabases', tbl_Databases.* FROM #SDB INNER JOIN SSLDBA..tbl_Databases ON #SDB.[name]=DatabaseName ORDER BY #SDB.recovery_model_desc ASC, #SDB.[name] ASC;
	COMMIT
	IF @AutoApplyTemplate = 'RUNAPPLY' BEGIN
		IF (SELECT TextValue FROM SSLDBA..tbl_Param WHERE Param = 'TemplateOverrideRequired') = 'N'BEGIN
			EXEC SSLDBA..up_ApplyTemplate;
			EXEC msdb..sp_start_job N'SSL_Weekly_Job', @step_name='Run SSL Health Check Script';
		END
		ELSE BEGIN
			SELECT 'Cannot Auto Apply template' AS 'TemplateOverrideRequired'
		END
	END
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS '!!ROLLBACK!!'
	IF @@TRANCOUNT > 0 ROLLBACK
END CATCH
DROP TABLE #SSL_tempDB; DROP TABLE #TempUpdates; DROP TABLE #SDB; DROP TABLE #TDB; DROP TABLE #TSDB;