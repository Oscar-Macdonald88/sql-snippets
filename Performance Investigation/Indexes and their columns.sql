SELECT ind.name AS [Index Name],
    ind.is_primary_key AS [Is primary key],
    col.name AS [Column Name],
    ic.is_included_column AS [Column is included]
FROM sys.indexes ind
INNER JOIN sys.index_columns ic ON ind.object_id = ic.object_id
    AND ind.index_id = ic.index_id
INNER JOIN sys.columns col ON ic.object_id = col.object_id
    AND ic.column_id = col.column_id
INNER JOIN sys.tables t ON ind.object_id = t.object_id
WHERE 1 = 1
    --ind.is_primary_key = 0 AND
    --ind.is_unique = 0 AND
    AND ind.is_unique_constraint = 0
    AND t.is_ms_shipped = 0 
    --and t.name = 'alf_node_properties'
GROUP BY ind.name,
    ind.is_primary_key,
    ic.index_column_id,
    ic.is_included_column,
    col.name 
ORDER BY ind.name DESC,
    ind.is_primary_key,
    ic.index_column_id,
    ic.is_included_column,
    col.name;
