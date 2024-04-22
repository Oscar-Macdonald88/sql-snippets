USE dbname; -- Make sure to update the database name  
GO  
SELECT name AS stats_name,   
    STATS_DATE(object_id, stats_id) AS statistics_update_date  
FROM sys.stats   
-- WHERE object_id = OBJECT_ID('schema.table'); --uncomment and add a specific table if needed.  
GO  