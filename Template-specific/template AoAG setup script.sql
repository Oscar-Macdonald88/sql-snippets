/*	Configure AoHA Alerting in DBA Template 5.3.0.208.013
	Please note: This does NOT automatically set the Primary/Secondary options. 
		You MUST manually set these below (read the code). 
*/
	--Setup the [tbl_AlwaysOnGroups] table
	INSERT INTO [SSLDBA].[dbo].[tbl_AlwaysOnGroups]
	SELECT DISTINCT
		T2.name AS [GroupName],
		1 AS [IsMonitored]
	FROM 
		sys.dm_hadr_availability_group_states AS T1
		INNER JOIN sys.availability_groups AS T2 ON (T1.group_id = T2.group_id)
	WHERE T2.name NOT IN (SELECT GroupName FROM [SSLDBA].[dbo].[tbl_AlwaysOnGroups])
	SELECT * FROM [SSLDBA].[dbo].[tbl_AlwaysOnGroups]
 
	--Setup the [tbl_Databases_AlwaysOn_Support] table
	;WITH aoha AS (
		SELECT DISTINCT
			T2.name AS [GroupName],
			T4.name AS [DatabaseName],
			T5.DailyBackupType,
			T1.primary_replica AS [Primary]
		FROM 
			sys.dm_hadr_availability_group_states AS T1
			INNER JOIN sys.availability_groups AS T2 ON (T1.group_id = T2.group_id)
			INNER JOIN sys.dm_hadr_database_replica_states AS T3 ON (T3.group_id = T1.group_id)
			INNER JOIN sys.databases AS T4 ON (T4.group_database_id = T3.group_database_id)
			INNER JOIN SSLDBA.dbo.tbl_Databases T5 ON (T4.name = T5.DatabaseName)
	)
	INSERT INTO [SSLDBA].[dbo].[tbl_Databases_AlwaysOn_Support] ([DatabaseName], [GroupName], [PrimaryStateTemplateBackup], [PrimaryStateDailyBackup], [PrimaryStateTemplateBackupType], [PrimaryStateLogBackup], [PrimaryStateWeeklyDBCC], [PrimaryStateWeeklyDefrag], [SecondaryStateTemplateBackup], [SecondaryStateDailyBackup], [SecondaryStateTemplateBackupType], [SecondaryStateLogBackup], [SecondaryStateWeeklyDBCC], [SecondaryStateWeeklyDefrag])
	SELECT 
		DatabaseName AS [DatabaseName],
		GroupName AS [GroupName],
		'Y' AS [PrimaryStateTemplateBackup], -- MANUALLY UPDATE THIS
		'Y' AS [PrimaryStateDailyBackup], -- MANUALLY UPDATE THIS
		'F' AS [PrimaryStateTemplateBackupType], -- MANUALLY UPDATE THIS
		'Y' AS [PrimaryStateLogBackup], -- MANUALLY UPDATE THIS
		'Y' AS [PrimaryStateWeeklyDBCC], -- MANUALLY UPDATE THIS
		'Y' AS [PrimaryStateWeeklyDefrag], -- MANUALLY UPDATE THIS
		'N' AS [SecondaryStateTemplateBackup], -- MANUALLY UPDATE THIS
		'N' AS [SecondaryStateDailyBackup], -- MANUALLY UPDATE THIS
		'F' AS [SecondaryStateTemplateBackupType], -- MANUALLY UPDATE THIS
		'N' AS [SecondaryStateLogBackup], -- MANUALLY UPDATE THIS
		'N' AS [SecondaryStateWeeklyDBCC], -- MANUALLY UPDATE THIS
		'N' AS [SecondaryStateWeeklyDefrag] -- MANUALLY UPDATE THIS 
	FROM aoha
	WHERE DatabaseName NOT IN (SELECT DatabaseName FROM [SSLDBA].[dbo].[tbl_Databases_AlwaysOn_Support])
	SELECT * FROM [SSLDBA].[dbo].[tbl_Databases_AlwaysOn_Support]
 
	--Configure the Alertable options 
	--EXEC SSLDBA.dbo.up_AlwaysOnEventSetup 90;--(16 currently)

	--SSLDBA..up_ApplyAGSupport 'PAGSPS01', 'Primary'
 
--TRUNCATE TABLE [SSLDBA].[dbo].[tbl_Databases_AlwaysOn_Support]