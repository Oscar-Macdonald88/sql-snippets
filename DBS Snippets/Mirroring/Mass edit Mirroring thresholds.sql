/*
	The below scripts generate T-SQL which you can copy/paste into a new query window. 
	- The first script will show you all of the thresholds for the databases.
	- The second will allow you to increase the thresholds, as to avoid paging/tickets. 
	- The third will allow you to reset the values back to their defaults.
 
	Cheers, Alex - 31/10/2012
*/
 
--View the current thresholds.
	SELECT 'EXEC sp_dbmmonitorhelpalert ['+name+'];' 
	FROM sys.databases 
	WHERE name IN (SELECT DB_Name(database_id) FROM sys.database_mirroring WHERE mirroring_guid IS NOT NULL)
 
--Increase the thresholds by 10 fold.
	SELECT 
		'EXEC sp_dbmmonitorchangealert ['+name+'], 1, 1500, 1;',
		'EXEC sp_dbmmonitorchangealert ['+name+'], 2, 102400000, 1;',
		'EXEC sp_dbmmonitorchangealert ['+name+'], 3, 102400000, 1;'
	FROM sys.databases 
	WHERE name IN (SELECT DB_Name(database_id) FROM sys.database_mirroring WHERE mirroring_guid IS NOT NULL)
 
--Reset the thresholds back to their normal level.
	SELECT 
		'EXEC sp_dbmmonitorchangealert ['+name+'], 1, 15, 1;',
		'EXEC sp_dbmmonitorchangealert ['+name+'], 2, 1024000, 1;',
		'EXEC sp_dbmmonitorchangealert ['+name+'], 3, 1024000, 1;'
	FROM sys.databases 
	WHERE name IN (SELECT DB_Name(database_id) FROM sys.database_mirroring WHERE mirroring_guid IS NOT NULL)