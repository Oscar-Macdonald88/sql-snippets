SELECT sum(ghost_record_count) total_ghost_records, db_name(database_id) 
FROM sys.dm_db_index_physical_stats (NULL, NULL, NULL, NULL, NULL)
group by database_id
order by total_ghost_records desc