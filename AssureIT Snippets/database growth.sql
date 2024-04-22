/* Data */
USE [EIT_DBA]
GO

DECLARE @cols as NVARCHAR(MAX);
DECLARE @query as NVARCHAR(MAX);
		
SET @cols = STUFF((SELECT distinct ',' + QUOTENAME(name)
FROM sys.databases
WHERE 1 = 1
	AND name <> 'tempdb'
FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)') ,1,1,'');

SET @query = 'SELECT Collected, ' + @cols + ' from 
(
		SELECT DISTINCT CAST(a.CounterDateTime AS VARCHAR(16)) AS Collected
			,COALESCE(b.InstanceName, ''-'') AS database_name
			,CASE 
				WHEN CAST(MAX(a.CounterValue) / 1024 AS BIGINT) < 1
					THEN 1
				ELSE CAST(MAX(a.CounterValue) / 1024 AS BIGINT)
				END AS DataFileSizeMB
		FROM dbo.CounterData a
			,dbo.CounterDetails b
		WHERE 1 = 1
			AND a.CounterID = b.CounterID
			AND b.ObjectName = dbo.ConfigValueGet(''dba_trend_instance'') + '':Databases'' COLLATE Latin1_General_CI_AS
			AND b.CounterName = ''Data File(s) Size (KB)''
			AND COALESCE(b.InstanceName, ''-'') LIKE COALESCE(b.InstanceName, ''-'')
			AND a.CounterDateTime LIKE ''%00:00%''
		GROUP BY COALESCE(b.InstanceName, ''-'')
			,CAST(a.CounterDateTime AS VARCHAR(16))
) x
pivot 
(
    AVG(DataFileSizeMB)
    for database_name in (' + @cols + ')
) p ';

EXECUTE (@query);