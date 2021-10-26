SELECT DB_NAME(database_id), mirroring_role_desc, mirroring_state_desc, REPLACE(REPLACE(mirroring_safety_level_desc, 'OFF', 'Asynchronous'), 'FULL', 'Synchronous') AS [Mode], '' AS [-],
		'ALTER DATABASE ['+DB_NAME(database_id)+'] SET PARTNER SUSPEND;' AS [1_Pause],
		'ALTER DATABASE ['+DB_NAME(database_id)+'] SET PARTNER RESUME;' AS [2_Resume]
	FROM master.sys.database_mirroring 
	WHERE mirroring_role=1
	ORDER BY DB_NAME(database_id)