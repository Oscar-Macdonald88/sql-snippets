-- Index DMVs
sys.dm_db_index_physical_stats -- Index size and fragmentation statistics
sys.dm_db_index_operational_stats -- Current index and table I/O statistics
sys.dm_db_index_usage_stats -- Index usage statistics by access type

SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbName'), NULL, NULL, NULL)
GO
-- index_level goes from leaves upwards, 0 being a leaf and the highest value is the root
-- the leaf level of avg_fragmentations_in_percent is often important to look at.
-- the leaf level of page_count and avg_page_space_used_in_percent is also handy

SELECT * FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) A -- Don't know why the 'A'  is there
GO