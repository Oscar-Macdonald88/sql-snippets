-- Statistics 
-- Exist to help the optimizer choose a good execution plan by estimating the selectivity of an operation
-- Store distribution details of the data within the table.
DBCC SHOW_STATISTICS ('people', stat_lastname); -- shows the statistics for a 'last_name' column

-- As data changes, statistics become outdated
-- They are updated automatically or on demand
--  AUTO_UPDATE_STATISTICS: Database option (ON by default)
--  UPDATE STATISTICS: Manually trigger an update for a table or specific statistics
--  sp_updatestats: updates all statistics in a database
--  ALTER INDEX REBUILD: Also rebuilds the statistics with FULLSCAN