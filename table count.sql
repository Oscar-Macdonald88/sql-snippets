DECLARE @tbl_name VARCHAR(max) = '' --insert table name here

SELECT SUM(row_count)
FROM sys.dm_db_partition_stats
WHERE object_id = OBJECT_ID(@tbl_name)
	AND (
		index_id = 0
		OR index_id = 1
		)
