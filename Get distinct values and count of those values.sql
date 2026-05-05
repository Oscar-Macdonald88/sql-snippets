SELECT 
    ColumnName,
    COUNT(ColumnName) AS ValueCount
FROM 
    TableName
GROUP BY 
    ColumnName
ORDER BY 
    ValueCount DESC;