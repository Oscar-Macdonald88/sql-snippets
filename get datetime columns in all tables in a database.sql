SELECT 
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    c.name AS ColumnName,
    TYPE_NAME(c.user_type_id) AS DataType
FROM 
    sys.columns c
INNER JOIN 
    sys.tables t ON c.object_id = t.object_id
WHERE 
    TYPE_NAME(c.user_type_id) IN ('date', 'datetime', 'datetime2', 'smalldatetime', 'datetimeoffset', 'time')
ORDER BY 
    SchemaName, TableName, ColumnName;