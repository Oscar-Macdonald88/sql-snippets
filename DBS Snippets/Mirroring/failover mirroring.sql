SELECT DB_NAME(database_id), mirroring_role_desc, mirroring_state_desc, REPLACE(REPLACE(mirroring_safety_level_desc, 'OFF', 'Asynchronous'), 'FULL', 'Synchronous') AS [Mode], '' AS [-],
		'ALTER DATABASE ['+DB_NAME(database_id)+'] SET PARTNER SAFETY FULL' AS [1_Synchronise],
		'ALTER DATABASE ['+DB_NAME(database_id)+'] SET PARTNER FAILOVER' AS [2_Failover], --Also: SUSPEND or RESUME
		'ALTER DATABASE ['+DB_NAME(database_id)+'] SET PARTNER SAFETY OFF' AS [3_Asynchronise]
	FROM master.sys.database_mirroring 
	WHERE mirroring_role=1
	ORDER BY DB_NAME(database_id)