--1) Run below (if required) to get full list of available SQL Server counters for your current instance
--2) Add your counters below (if required)
--3) Run script
/*
SELECT RTRIM(LTRIM(counter_name)) AS 'Counter Name', ',('',\"\${server}' + REPLACE(RTRIM(LTRIM(object_name)),'MSSQL$' + @@SERVICENAME , '') + '\' + RTRIM(LTRIM(counter_name)) + '\"'', ''' + RTRIM(LTRIM(counter_name)) + ''')' AS 'SQL Counters ($counters)' FROM sys.dm_os_performance_counters ORDER BY counter_name
WHERE counter_name LIKE '%%';
GO
*/
DECLARE @TotalOutputCycles INT = 20 -- Cycles before auto stop (WARNING, setting this too high and failing to stop the query WILL result in this running in the background for an extended period of time)
DECLARE @TimeBetweenCycles VARCHAR(8) = '00:00:05' -- Time between each check HH:MM:SS
 
USE master
DECLARE @Server AS VARCHAR(100) = (SELECT 'MSSQL$' + @@SERVICENAME)
IF (@Server = 'MSSQL$MSSQLSERVER')BEGIN SET @Server = 'SQLSERVER' END
DECLARE @Counters TABLE (ID INT IDENTITY(1,1) PRIMARY KEY, CounterSet VARCHAR(100), CounterName VARCHAR(100), Loaded INT DEFAULT 0)
INSERT INTO @Counters (CounterSet, CounterName) VALUES
('\"\Processor(_Total)\% Processor Time\"','% Processor Time')
,(',\"\Memory\Available MBytes\"', 'Available MBytes')
,(',\"\${server}:Memory Manager\Total Server Memory (KB)\"','Total Server Memory')
,(',\"\${server}:Buffer Manager\Page life expectancy\"','Page life expectancy')
,(',\"\${server}:Buffer Manager\Page lookups/sec\"','Page lookups/sec')
,(',\"\${server}:Buffer Manager\Page reads/sec\"','Page reads/sec')
,(',\"\${server}:Buffer Manager\Page writes/sec\"','Page writes/sec')
,(',\"\${server}:Buffer Manager\Lazy writes/sec\"','Lazy writes/sec')
/* \/ \/ \/ \/ \/ ADD COUNTERS HERE \/ \/ \/ \/ \/ */
 
 
 
/* /\ /\ /\ /\ /\ ADD COUNTERS HERE /\ /\ /\ /\ /\ */
DECLARE @Count INT = 0
DECLARE @Row VARCHAR(100)
DECLARE @DateTime DATETIME;
DECLARE @PS VARCHAR(8000) = 'powershell.exe -Command $server = ''' + @Server + '''; $a = Get-counter -Counter '
WHILE ((SELECT COUNT(*) FROM @Counters WHERE Loaded = 0) != 0) BEGIN SET @PS = @PS + (SELECT TOP(1) CounterSet FROM @Counters WHERE Loaded = 0 ORDER BY ID) UPDATE TOP(1) @Counters SET Loaded = 1 WHERE Loaded = 0 END
SET @PS = @PS + '; $a.CounterSamples "|" ft CookedValue -HideTableHeaders;'
SELECT LEN(@PS) AS 'Current Length', CASE WHEN LEN(@PS) >= 8000 THEN '!!ERROR!! Max length reached, Script will likely fail' ELSE CONVERT(VARCHAR(200),(8000 - LEN(@PS)))  END AS 'Free Characters'
DECLARE @PSResult TABLE (ResultID INT IDENTITY(1,1) PRIMARY KEY, CounterValue VARCHAR(255))
WHILE (1=1) BEGIN
	DELETE FROM @PSResult
	INSERT INTO @PSResult EXEC xp_cmdshell @PS
	SELECT CounterName, RTRIM(LTRIM(CounterValue)) AS 'CounterValue' FROM @Counters INNER JOIN @PSResult ON ID = (ResultID - (@Count * (SELECT COUNT(*) FROM @Counters)) - 1 - (4 * @Count)) WHERE CounterValue IS NOT NULL
	RAISERROR( '',0,1) WITH NOWAIT
	SET @Count = @Count + 1
	IF(@Count = @TotalOutputCycles)BEGIN BREAK END
	WAITFOR DELAY @TimeBetweenCycles;
END