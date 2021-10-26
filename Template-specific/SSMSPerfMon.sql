--1) Run below (if required) to get full list of available SQL Server counters for your current instance
--2) Add your counters below (if required)
--3) Run script
/*
SELECT RTRIM(LTRIM(counter_name)) AS 'Counter Name', ',('',\"\${server}' + REPLACE(RTRIM(LTRIM(object_name)),'MSSQL$' + @@SERVICENAME , '') + '\' + RTRIM(LTRIM(counter_name)) + '\"'')' AS 'SQL Counters ($counters)' FROM sys.dm_os_performance_counters
WHERE counter_name LIKE '%%'; 
GO
*/
DECLARE @TotalOutputCyles INT = 20 -- Cycles before auto stop (WARNING, setting this too high and failing to stop the query WILL result in this running in the background for an extended period of time)
DECLARE @TimeBetweenCyles VARCHAR(8) = '00:00:05' -- Time between each check HH:MM:SS
 
USE master
SET NOCOUNT ON
 
DECLARE @Server AS VARCHAR(100) = (SELECT 'MSSQL$' + @@SERVICENAME)
IF (@Server = 'MSSQL$MSSQLSERVER')BEGIN SET @Server = 'SQLSERVER' END
DECLARE @Counters TABLE (ID INT IDENTITY(1,1) PRIMARY KEY, CounterSet VARCHAR(100))
INSERT INTO @Counters (CounterSet) VALUES 
('\"\Processor(_Total)\% Processor Time\"')
,(',\"\Memory\Available MBytes\"')
,(',\"\${server}:Buffer Manager\Page life expectancy\"')
,(',\"\${server}:Buffer Manager\Page lookups/sec\"')
,(',\"\${server}:Buffer Manager\Page reads/sec\"')
,(',\"\${server}:Buffer Manager\Page writes/sec\"')
,(',\"\${server}:Buffer Manager\Lazy writes/sec\"')
/* \/ \/ \/ \/ \/ ADD COUNTERS HERE \/ \/ \/ \/ \/ */
 
 
 
/* /\ /\ /\ /\ /\ ADD COUNTERS HERE /\ /\ /\ /\ /\ */
DECLARE @Count INT = 0
DECLARE @Row VARCHAR(100)
DECLARE @DateTime DATETIME;
WITH CTE AS(SELECT CounterSet,RN = ROW_NUMBER()OVER(PARTITION BY CounterSet ORDER BY ID)FROM @Counters)
DELETE FROM CTE WHERE RN > 1
DECLARE @PS VARCHAR(8000) = 'powershell.exe -Command $server = ''' + @Server + '''; $a = Get-counter -Counter '
WHILE ((SELECT COUNT(*) FROM @Counters) != 0) BEGIN SET @PS = @PS + (SELECT TOP(1) CounterSet FROM @Counters ORDER BY ID) DELETE TOP(1) FROM @Counters WHERE ID IN (SELECT TOP(1) ID FROM @Counters ORDER BY ID) END
SET @PS = @PS + '; $b=0; foreach($row in $a.CounterSamples.Path){$c = [regex]::match($row,\"[^\\]*$\").captures.groups[0].Value; $a.CounterSamples[$b] "|" Add-Member NoteProperty -Name Name -Value $c; $b = $b +1}; $a.CounterSamples "|" ft Name, CookedValue -HideTableHeaders;'
DECLARE @PSResult TABLE (Result VARCHAR(255))
SELECT 'Switch to Messages panel' AS '           ^|^|^|^|^|^|^|^|^', LEN(@PS) AS 'Current Length', CASE WHEN LEN(@PS) = 8000 THEN '!!ERROR!! Max length reached' ELSE (8000 - LEN(@PS)) END AS 'Free Characters'
WHILE (1=1) BEGIN
       SET @Count = @Count + 1
       INSERT INTO @PSResult EXEC xp_cmdshell @PS
       DELETE FROM @PSResult WHERE Result IS NULL
       SET @DateTime = GETDATE()
       PRINT '------Cycle ' + CONVERT(VARCHAR,@Count) + ' of ' + CONVERT(VARCHAR,@TotalOutputCyles) + ' -- ' + CONVERT(VARCHAR(26), @DateTime, 108) + '------'
       WHILE ((SELECT COUNT(*) FROM @PSResult) != 0) BEGIN SET @Row = (SELECT TOP(1) * FROM @PSResult); PRINT @Row; DELETE TOP(1) FROM @PSResult END
       RAISERROR( '',0,1) WITH NOWAIT
       IF(@Count = @TotalOutputCyles)BEGIN BREAK END
       WAITFOR DELAY @TimeBetweenCyles;
END
PRINT '------------- FINISHED -------------'
