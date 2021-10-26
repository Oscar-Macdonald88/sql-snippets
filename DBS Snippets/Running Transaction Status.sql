--Transaction use per SPID (Tim Mutch idea)
--Also, if you have KILLED / ROLLBACK a SPID, you can watch it's memory use declining as it rolls back the transaction. 
--Useful for estimating how much longer your 100% rolled-back SPID will take to clear. 
	SELECT
		s.session_id AS [SPID],
		t.transaction_id,
		t.database_transaction_begin_time,
		DATEDIFF(SECOND, t.database_transaction_begin_time, GETDATE()) as [Run_Sec], '' AS [-],
		CONVERT(DECIMAL(38,2), (t.database_transaction_log_bytes_used+1.0)/1024) AS [Log_KB_Used], 
		CONVERT(DECIMAL(38,2), (t.database_transaction_log_bytes_reserved+1.0)/1024) AS [Log_KB_Reserved], '' AS [-],
		CONVERT(DECIMAL(38,2), (t.database_transaction_log_bytes_used+1.0)/1024/1024) AS [Log_MB_Used],
		CONVERT(DECIMAL(38,2), (t.database_transaction_log_bytes_reserved+1.0)/1024/1024) AS [Log_MB_Reserved]
	FROM sys.dm_tran_session_transactions s
	LEFT JOIN sys.dm_tran_database_transactions t ON (s.transaction_id = s.transaction_id)
	WHERE t.transaction_id > 1000
		AND t.database_id = DB_ID('<DatabaseName>') --SET THIS
		-- AND t.transaction_id = <SPID> --SET THIS
	ORDER BY s.session_id, s.transaction_id;