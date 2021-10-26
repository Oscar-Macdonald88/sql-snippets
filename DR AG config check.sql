WITH SuperScript AS (
		SELECT DatabaseName AS [Name], '' AS [SizeMB], '' AS [SSL_bkup], '' AS [Status], '' AS [Recovery], '*** REMOVE' AS [DBA_conf], '' AS [DR_HA], '' AS [Last_Log], '' AS [Last_Diff], '' AS [Last_Full], '' AS [Options] FROM SSLDBA.dbo.tbl_Databases WHERE DatabaseName NOT IN (SELECT name FROM sys.databases)
		UNION ALL
		SELECT
			sysdbs.name,
			MAX(LEFT(CONVERT(varchar, CAST(sz.SizeMB AS money), 1), LEN(CONVERT(varchar, CAST(sz.SizeMB AS money), 1)) - 3)) AS [SizeMB],
			CASE WHEN (ssldbs.TemplateBackup IS NOT NULL) THEN CASE WHEN (MAX(sysdbs.state_desc)<>'ONLINE' AND UPPER(ssldbs.TemplateBackup)='Y') THEN '* Y' ELSE UPPER(ssldbs.TemplateBackup) END ELSE '' END,
			CAST (CASE WHEN (sysdbs.is_read_only=1 AND MAX(sysdbs.state_desc)<>'OFFLINE') THEN 'READ_ONLY' WHEN (MAX(sysdbs.state_desc)='ONLINE') THEN 'online' WHEN (MAX(sysdbs.state_desc)='OFFLINE' AND (UPPER(ssldbs.TemplateBackup)='Y' OR MAX(ssldbs.LogBackupStart) IS NOT NULL OR MAX(ssldbs.LogBackupFinish) IS NOT NULL)) THEN '* OFFLINE' WHEN MAX(sysdbs.state_desc)='OFFLINE' THEN 'OFFLINE' WHEN (MAX(sysdbs.state_desc) IS NOT NULL) THEN MAX(sysdbs.state_desc) ELSE '' END + case when (max(ssldbs.[Status]) is null) then ' *' else '' end AS VARCHAR(64)),
			LOWER(MAX(sysdbs.recovery_model_desc)),
			CAST (CASE WHEN ((MAX(ssldbs.LogBackupStart) IS NULL OR MAX(ssldbs.LogBackupFinish) IS NULL) AND (MAX(ssldbs.LogBackupStart) IS NOT NULL OR MAX(ssldbs.LogBackupFinish) IS NOT NULL)) THEN '* incomplete' WHEN ((MAX(lsp.primary_database) IS NOT NULL OR MAX(lss.secondary_database) IS NOT NULL) AND MAX(ssldbs.LogBackupStart) IS NULL AND MAX(ssldbs.LogBackupFinish) IS NULL) THEN 'logship' WHEN ((MAX(lsp.primary_database) IS NOT NULL OR MAX(lss.secondary_database) IS NOT NULL) AND MAX(ssldbs.LogBackupStart) IS NOT NULL AND MAX(ssldbs.LogBackupFinish) IS NOT NULL) THEN '* FULL [LS]' WHEN (MAX(ssldbs.LogBackupStart) IS NOT NULL AND MAX(ssldbs.LogBackupFinish) IS NOT NULL AND MAX(sysdbs.recovery_model_desc)='SIMPLE') THEN '* FULL' WHEN (MAX(ssldbs.LogBackupStart) IS NOT NULL AND MAX(ssldbs.LogBackupFinish) IS NOT NULL) THEN 'full' WHEN (MAX(sysdbs.state_desc)='OFFLINE' AND 'Y' NOT IN (MAX(ssldbs.DailyBackup), MAX(ssldbs.TemplateBackup), MAX(ssldbs.WeeklyDBCC), MAX(ssldbs.WeeklyDBCC), MAX(ssldbs.ReportSpaceUsed))) THEN 'offline' WHEN (MAX(sysdbs.state_desc)='OFFLINE') THEN '* ONLINE' WHEN (MAX(sysdbs.state)=0 AND ssldbs.DatabaseName IS NOT NULL AND MAX(sysdbs.recovery_model_desc)='FULL' AND LOWER(ssldbs.DatabaseName)<>'model' AND UPPER(ssldbs.TemplateBackup)='Y') THEN '* SIMPLE' WHEN (ssldbs.DatabaseName IS NOT NULL AND UPPER(ssldbs.TemplateBackup)<>'N') THEN 'simple' WHEN (ssldbs.DatabaseName IS NOT NULL AND UPPER(ssldbs.TemplateBackup)='N') THEN 'none' WHEN (ssldbs.DatabaseName IS NULL) THEN '*** ADD' ELSE 'CHECK Tbl_Databases' END AS VARCHAR(64)),
			CASE WHEN (MAX(lsp.primary_database) IS NOT NULL) THEN 'LS: primary' WHEN (MAX(lss.secondary_database) IS NOT NULL) THEN 'LS: secondary' WHEN (MAX(mir.mirroring_role_desc) IS NOT NULL) THEN 'MIR: '+LOWER(MAX(mir.mirroring_role_desc)) WHEN (MAX(CONVERT(int,sysdbs.is_published))=1 OR MAX(CONVERT(int,sysdbs.is_merge_published))=1) THEN 'REPL: publisher'	WHEN (MAX(CONVERT(int,sysdbs.is_subscribed))=1) THEN 'REPL: subscriber'	WHEN (MAX(CONVERT(int,sysdbs.is_distributor))=1) THEN 'REPL: distributor' ELSE '' END,
			CAST (CASE WHEN ((DATEDIFF(M,MAX(logSet.backup_finish_date),GETDATE()))>=MAX(ssldbs.LogBackupFreq) AND MAX(sysdbs.state_desc)<>'OFFLINE') THEN ' *' ELSE '' END AS VARCHAR(64)) + CONVERT(VARCHAR(3),(DATEDIFF(S,MAX(logSet.backup_finish_date),GETDATE())/86400))+'d, ' + RIGHT('  '+CONVERT(VARCHAR(2),(DATEDIFF(S,MAX(logSet.backup_finish_date),GETDATE())%86400)/3600),3)+'h, ' + RIGHT('  '+CONVERT(VARCHAR(2),(((DATEDIFF(S,MAX(logSet.backup_finish_date),GETDATE())%86400)%3600)/60)),2)+'m',
			CAST (CASE WHEN ((DATEDIFF(S,MAX(differentialSet.backup_finish_date),GETDATE())/86400)>=1 AND MAX(differentialSet.backup_finish_date)>MAX(dataSet.backup_finish_date) AND MAX(sysdbs.state_desc)<>'OFFLINE') THEN '* ' ELSE '' END AS VARCHAR(64)) + CONVERT(VARCHAR(3),(DATEDIFF(S,MAX(differentialSet.backup_finish_date),GETDATE())/86400))+'d, ' + RIGHT('  '+CONVERT(VARCHAR(2),(DATEDIFF(S,MAX(differentialSet.backup_finish_date),GETDATE())%86400)/3600),2)+'h, ' + RIGHT('  '+CONVERT(VARCHAR(2),(((DATEDIFF(S,MAX(differentialSet.backup_finish_date),GETDATE())%86400)%3600)/60)),2)+'m',
			CAST (CASE WHEN ((DATEDIFF(S,MAX(dataSet.backup_finish_date),GETDATE())/86400)>=1 AND (MAX(differentialSet.backup_finish_date) IS NULL OR MAX(differentialSet.backup_finish_date)<MAX(dataSet.backup_finish_date)) AND MAX(sysdbs.state_desc)<>'OFFLINE') THEN '* ' ELSE '' END AS VARCHAR(64)) + CONVERT(VARCHAR(3),(DATEDIFF(S,MAX(dataSet.backup_finish_date),GETDATE())/86400))+'d, ' + RIGHT('  '+CONVERT(VARCHAR(2),(DATEDIFF(S,MAX(dataSet.backup_finish_date),GETDATE())%86400)/3600),2)+'h, ' + RIGHT('  '+CONVERT(VARCHAR(2),(((DATEDIFF(S,MAX(dataSet.backup_finish_date),GETDATE())%86400)%3600)/60)),2)+'m',
			CASE WHEN ((UPPER(MAX(ssldbs.WeeklyDBCC))='Y' OR UPPER(MAX(ssldbs.WeeklyDefrag))='Y') AND MAX(sysdbs.state_desc)<>'ONLINE') THEN '* ' ELSE '' END + UPPER('['+MAX(ssldbs.DailyBackup)+MAX(ssldbs.TemplateBackup)+MAX(ssldbs.DailyBackupType)+CASE WHEN (MAX(ssldbbs.DatabaseName) IS NOT NULL) THEN '+A' ELSE '' END+'] '+MAX(WeeklyDBCC)+MAX(WeeklyDefrag)+MAX(ReportSpaceUsed)) --UPPER(MAX(ssldbs.WeeklyDBCC)+MAX(ssldbs.WeeklyDefrag)+MAX(ssldbs.ReportSpaceUsed))
		FROM
			master.sys.databases sysdbs
			LEFT JOIN (SELECT database_name, MAX(backup_finish_date) AS backup_finish_date, type FROM msdb.dbo.backupset WHERE type='L' GROUP BY database_name, type) AS logSet ON (logSet.database_name=sysdbs.name)
			LEFT JOIN (SELECT database_name, MAX(backup_finish_date) AS backup_finish_date, type FROM msdb.dbo.backupset WHERE type='I' GROUP BY database_name, type) AS differentialSet ON (differentialSet.database_name=sysdbs.name)
			LEFT JOIN (SELECT database_name, MAX(backup_finish_date) AS backup_finish_date, type FROM msdb.dbo.backupset WHERE type='D' GROUP BY database_name, type) AS dataSet ON (dataSet.database_name=sysdbs.name)
			LEFT JOIN SSLDBA.dbo.tbl_Databases ssldbs ON (ssldbs.DatabaseName=sysdbs.name)
			LEFT JOIN SSLDBA.dbo.tbl_DatabaseBackups ssldbbs ON (ssldbbs.DatabaseName=sysdbs.name)
			LEFT JOIN msdb.dbo.log_shipping_monitor_primary lsp ON (lsp.primary_database=sysdbs.name)
			LEFT JOIN msdb.dbo.log_shipping_monitor_secondary lss ON (lss.secondary_database=sysdbs.name)
			LEFT JOIN sys.database_mirroring mir ON (DB_NAME(mir.database_id)=sysdbs.name)
			LEFT JOIN (SELECT dbid, SUM(size)/128 AS [SizeMB] FROM sys.sysaltfiles WHERE groupid <> 0 GROUP BY dbid) sz ON (sysdbs.database_id = sz.dbid)
		GROUP BY sysdbs.name, ssldbs.DatabaseName, ssldbs.TemplateBackup, sysdbs.recovery_model_desc, sysdbs.is_read_only
	)
	SELECT [Name], [SizeMB], [SSL_bkup], [Status], [Recovery], [DBA_conf], [DR_HA], [Last_Log], [Last_Diff], [Last_Full], [Options]		
	FROM SuperScript
	WHERE Name LIKE '%%'
	ORDER BY Name


	Select * from sys.dm_hadr_database_replica_cluster_states 
	Select * from sys.dm_os_cluster_nodes
	Select * from sys.dm_hadr_availability_replica_cluster_nodes
	Select * from sys.dm_hadr_availability_replica_cluster_states
	Select * from sys.dm_hadr_availability_replica_states
	Select * from sys.dm_hadr_cluster
	Select * from sys.dm_hadr_cluster_members
	Select * from sys.dm_hadr_instance_node_map
	Select * from sys.dm_hadr_name_id_map