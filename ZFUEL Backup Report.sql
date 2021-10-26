USE SSLSites
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;

		WITH backups AS (
			SELECT
				c.CustCode,
				ds.Name AS [ServerName],
				db.Name AS [DatabaseName],
				db.EndDate,
				vdb.IsDailyBackup AS [DailyBackup],
				vdb.IsTemplateBackup AS [TemplateBackup],
				vdb.BackupTypeInd AS [DailyBackupType],
				CASE WHEN (vdb.LogBackupStart IS NOT NULL AND vdb.LogBackupFinish IS NOT NULL) THEN 'Y' ELSE 'N' END AS [SSLLogBackups],
					DATEDIFF(MINUTE,(dbbl.StartDate),GETDATE()) AS [Last_Log_Min],
					dbbl.Location AS [Last_Log_Location],
					DATEDIFF(MINUTE,(dbbd.StartDate),GETDATE()) AS [Last_Diff_Min],
					dbbd.Location AS [Last_Diff_Location],
					DATEDIFF(MINUTE,(dbbf.StartDate),GETDATE()) AS [Last_Full_Min],
					dbbf.Location AS [Last_Full_Location],
					CONVERT(VARCHAR(3),(DATEDIFF(S,(dbbl.StartDate),GETDATE())/86400))+'d, ' + RIGHT('  '+CONVERT(VARCHAR(2),(DATEDIFF(S,(dbbl.StartDate),GETDATE())%86400)/3600),3)+'h, ' + RIGHT('  '+CONVERT(VARCHAR(2),(((DATEDIFF(S,(dbbl.StartDate),GETDATE())%86400)%3600)/60)),2)+'m' AS [Last_Log],
					CONVERT(VARCHAR(3),(DATEDIFF(S,(dbbd.StartDate),GETDATE())/86400))+'d, ' + RIGHT('  '+CONVERT(VARCHAR(2),(DATEDIFF(S,(dbbd.StartDate),GETDATE())%86400)/3600),3)+'h, ' + RIGHT('  '+CONVERT(VARCHAR(2),(((DATEDIFF(S,(dbbd.StartDate),GETDATE())%86400)%3600)/60)),2)+'m' AS [Last_Diff],
					CONVERT(VARCHAR(3),(DATEDIFF(S,(dbbf.StartDate),GETDATE())/86400))+'d, ' + RIGHT('  '+CONVERT(VARCHAR(2),(DATEDIFF(S,(dbbf.StartDate),GETDATE())%86400)/3600),3)+'h, ' + RIGHT('  '+CONVERT(VARCHAR(2),(((DATEDIFF(S,(dbbf.StartDate),GETDATE())%86400)%3600)/60)),2)+'m' AS [Last_Full]
			FROM tbl_Customer c
			LEFT JOIN tbl_Device d ON d.CustomerID=c.CustomerID
			LEFT JOIN tbl_DeviceService ds ON ds.DeviceID=d.DeviceID
			LEFT JOIN tbl_DBDatabase db ON db.InstanceID=ds.DeviceServiceID
			LEFT JOIN (
				select dbs.*
				from tbl_DBDatabaseSetting dbs
				inner join (
					select max(DatabaseSettingID) as DatabaseSettingID, DatabaseID
					from tbl_DBDatabaseSetting
					group by DatabaseID
				) MostRecent on (dbs.DatabaseSettingID = MostRecent.DatabaseSettingID)
			) dbds ON (dbds.DatabaseID=db.DatabaseID)
			LEFT JOIN vw_Databases vdb ON (vdb.CustCode=c.CustCode AND vdb.ServerName=ds.Name AND vdb.DatabaseName=db.Name)
				LEFT JOIN (SELECT DatabaseID, MAX(StartDate) AS [StartDate], MAX(Location) AS [Location] FROM tbl_DBDatabaseBackup WHERE Type='I' AND EndDate > DATEADD(MONTH, -1, GETDATE()) GROUP BY DatabaseID) AS dbbd ON db.DatabaseID=dbbd.DatabaseID --DIFF
				LEFT JOIN (SELECT DatabaseID, MAX(StartDate) AS [StartDate], MAX(Location) AS [Location] FROM tbl_DBDatabaseBackup WHERE Type='L' AND EndDate > DATEADD(MONTH, -1, GETDATE()) GROUP BY DatabaseID) AS dbbl ON db.DatabaseID=dbbl.DatabaseID --LOG
				LEFT JOIN (SELECT DatabaseID, MAX(StartDate) AS [StartDate], MAX(Location) AS [Location] FROM tbl_DBDatabaseBackup WHERE Type='D' AND EndDate > DATEADD(MONTH, -1, GETDATE()) GROUP BY DatabaseID) AS dbbf ON db.DatabaseID=dbbf.DatabaseID --FULL
			WHERE 1=1
				AND c.CustCode='ZFUEL'
				AND (db.EndDate IS NULL OR db.EndDate > DATEADD(DAY, -14, GETDATE()))
				AND DeviceServiceID in (select DeviceServiceID from vw_CurrentDeviceList where CustCode = 'ZFUEL')
				AND (1 NOT IN (999, 1) OR (1 IN (999, 1) AND lower(DatabaseName) <> 'tempdb')) -- Option 1
				AND (ServerName like '%')
				AND (ServerName not like '')
		)
		SELECT
			ServerName,
			DatabaseName,
			--BEGIN LOG
				CASE
					WHEN (EndDate is not null) THEN 'Missing: '
					WHEN (Last_Log_Min IS NOT NULL AND Last_Log_Min<=1440) THEN 'Good: '
					ELSE 'Missing: '
				END +Last_Log +
				CASE
					WHEN (SSLLogBackups='Y') THEN ' (SSL Template is configured to take this backup.)' ELSE '' END
			AS [Last_Log],
			--BEGIN DIFF
				CASE
					WHEN (EndDate is not null) THEN 'NA'
					WHEN (Last_Diff_Min>=1440 AND Last_Full_Min>=1440) THEN 'Missing: '
					WHEN (Last_Diff_Min<=1440 AND (Last_Full_Min>1440 OR Last_Diff_Min<Last_Full_Min)) THEN 'Good: '
					ELSE ''
				END +Last_Diff+ CASE WHEN (TemplateBackup='Y' AND DailyBackupType='D') THEN ' (SSL Template is configured to take this backup).' ELSE '' END
			AS [Last_Diff],
			--BEGIN FULL
				CASE
					WHEN (EndDate is not null) THEN 'NA'
					WHEN ((Last_Diff_Min>=1440 AND Last_Full_Min>=1440) OR (Last_Diff_Min IS NULL AND Last_Full_Min>=1440)) THEN 'Missing: '
					WHEN (((Last_Diff_Min>=1440 OR Last_Full_Min<Last_Diff_Min) AND Last_Full_Min<1440) OR (Last_Diff_Min IS NULL AND Last_Full_Min<1440)) THEN 'Good: '
					WHEN '7' != '' AND (Last_Diff_Min is not null AND Last_Full_Min>=((7 * 24) * 60)) THEN 'Missing: '
					ELSE ''
				END + Last_Full+ CASE WHEN (TemplateBackup='Y' AND DailyBackupType='F') THEN ' (SSL Template is configured to take this backup.)' ELSE '' END
			AS [Last_Full]
		FROM backups
		ORDER BY CustCode, ServerName,
	 DatabaseName ASC