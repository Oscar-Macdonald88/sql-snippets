--Read the SQL Server ERRORLOGs to find Log Shipping problems.
--Quite difficult to use, but if you're REALLY desperate, give it a go.
	SELECT 'Query below = ' AS [ ], 'Search ErrorLog for:' AS [ ], '"Shipping"' AS [ ]
	EXEC xp_readerrorlog 0,1,"Shipping",Null
	SELECT '' AS [ ] UNION ALL SELECT ''
	IF (SELECT COUNT(*) FROM msdb.dbo.log_shipping_monitor_primary)>0 BEGIN
		SELECT 'Query below = ' AS [ ], 'Search ErrorLog for:' AS [ ], '"Backup"' AS [ ]
		EXEC xp_readerrorlog 0,1,"Backup",Null
		SELECT '' AS [ ] UNION ALL SELECT ''
	END
	IF (SELECT COUNT(*) FROM msdb.dbo.log_shipping_monitor_secondary)>0 BEGIN
		SELECT 'Query below = ' AS [ ], 'Search ErrorLog for:' AS [ ], '"Restore"' AS [ ]
		EXEC xp_readerrorlog 0,1,"Restore",Null
		SELECT '' AS [ ] UNION ALL SELECT ''
	END
	SELECT 'Query below = ' AS [ ], 'Search ErrorLog for:' AS [ ], '"Error"' AS [ ] UNION ALL SELECT 'Query bottom =', 'Error Log dictionary', ''
	--Execute it on Primary/Secondary server
	EXEC xp_readerrorlog 0,1,"Error",Null
	--Query to check the Log Shipping related error messages
	SELECT error, severity, description FROM master.sys.sysmessages where description LIKE '%shipping%' AND msglangid=1033