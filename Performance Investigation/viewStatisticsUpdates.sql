-- Make sure to use the correct database and table below
-- use dbname
SELECT sp.stats_id, 
       name, 
       filter_definition, 
       last_updated, 
       rows, 
       rows_sampled,
	   (rows_sampled / rows) * 100 as sample_percentage,
       steps, 
       unfiltered_rows, 
       modification_counter
FROM sys.stats AS stat
     CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp
--WHERE stat.object_id = OBJECT_ID('Encounter.PatientEncounter'); --Table Name
