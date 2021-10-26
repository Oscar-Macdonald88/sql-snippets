SELECT DB_NAME(database_id),* 
	FROM sys.database_mirroring 
	WHERE mirroring_state_desc IS NOT NULL