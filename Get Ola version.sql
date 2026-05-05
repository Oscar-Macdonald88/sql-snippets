
SELECT 
    OBJECT_NAME(object_id) AS ProcedureName,
    SUBSTRING(definition, 
              PATINDEX('%Version%', definition), 
              50) AS VersionInfo
FROM sys.sql_modules
WHERE OBJECT_NAME(object_id) IN (
    'DatabaseBackup', 'DatabaseIntegrityCheck', 'IndexOptimize'
);
