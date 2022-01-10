SELECT d.name AS [Database Name],
[Database Type] = CASE 
WHEN d.name IN ('master', 'model', 'msdb', 'tempdb') THEN 'System Database'
ELSE 'User Database'
END,
SUSER_SNAME(d.owner_sid) AS [Owner], 
d.create_date AS [Date Created], 
d.compatibility_level AS [Compatibility Level], 
d.collation_name AS [Collation], 
d.user_access_desc AS [Access Type], 
d.state_desc AS [Current State], 
d.recovery_model_desc AS [Recovery Model],
f.name AS [File Name],
[File Type] = CASE
WHEN f.type_desc = 'ROWS' THEN 'Data File'
WHEN f.type_desc = 'LOG' THEN 'Transaction Log File'
ELSE 'Other'
END,
f.physical_name AS [File Location],
f.size/1024 as [Size (MB)]
FROM sys.databases d
join sys.master_files f
on d.database_id = f.database_id
ORDER BY [Database Type] DESC, [Database Name]