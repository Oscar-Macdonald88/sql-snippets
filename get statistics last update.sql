SELECT
	db_name() as DatabaseName,
	s.name as SchemaName,
    t.name as TableName,
    st.name AS StatisticName,
    sp.last_updated
FROM
	sys.tables t
JOIN
    sys.stats AS st on st.object_id = t.object_id
JOIN
	sys.schemas s on t.schema_id = s.schema_id
CROSS APPLY 
    sys.dm_db_stats_properties(st.object_id, st.stats_id) AS sp
WHERE 
    OBJECTPROPERTY(st.object_id, 'IsUserTable') = 1
order by s.name, t.name, st.name;
