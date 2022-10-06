--************************************************
--Server Anaylysis using EIT_DBA
--************************************************
USE [EIT_DBA]
GO
SET NOCOUNT ON;
-- DEBUG params
DECLARE @review_start_datetime datetime;
DECLARE @review_end_datetime datetime;
DECLARE @review_database nvarchar(128);
SET @review_start_datetime = '2022-08-19 13:00:00';
SET @review_end_datetime = '2022-08-19 16:00:00';
SET @review_database = 'SDS';
DECLARE @now datetime;
SET @now = GETDATE();
-- CHECK input is correct
IF @review_database IS NULL
BEGIN
    PRINT 'Error - You must enter a database for review - Check input.';
    RETURN;
END;
IF @review_start_datetime >= @review_end_datetime
BEGIN
    PRINT 'Error - Invalid @review_start_datetime and @review_end_datetime entered - Check input.';
    RETURN;
END;
IF @review_start_datetime IS NULL
SET @review_start_datetime = DATEADD(HOUR,-1,@now);
IF @review_end_datetime IS NULL
SET @review_end_datetime = @now;
IF DATEDIFF(DAY, @review_start_datetime, @now) > 90 OR @review_start_datetime > @now
BEGIN
    PRINT 'Error - Invalid @review_start_datetime entered - Check input..';
    RETURN;
END;
IF DATEDIFF(DAY, @review_end_datetime, @now) > 90 OR @review_end_datetime > @now
BEGIN
    PRINT 'Error - Invalid @review_end_datetime entered - Check input..';
    RETURN;
END;
-- Print Header
SELECT 'Assure-IT_Analysis :' AS [Info], @@VERSION AS [SQLVersion]
SELECT @review_database AS [Review_Database], @review_start_datetime AS [Review_Start_DateTime], @review_end_datetime AS [Review_End_Datetime];
SELECT 'Server Info:';
EXEC xp_msver;
-- ******************************
-- ** Instance Stats
-- ******************************
-- Get Processor Stats:
SELECT 'Processor Stats:' AS [Info], 'Processors Utilisation < 80%' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, COALESCE(b.InstanceName, '-') AS Processor
, CAST(a.CounterValue AS DECIMAL(10, 5)) AS PercentProcessorTime
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = 'Processor'
    AND b.CounterName = '% Processor Time'
    AND b.InstanceName = '_Total'
    AND COALESCE(b.InstanceName, '-') LIKE COALESCE(b.InstanceName, '-')
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
	and a.CounterValue <> 0 -- about half of the entries return as 0, filter these out
ORDER BY Collected;
SELECT 'Processor Queue Length Stats:' AS [Info], 'Queue length < 4 per CPU' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, a.CounterValue AS PercentProcessorQueueLength
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = 'System'
    AND b.CounterName = 'Processor Queue Length'
    --AND b.InstanceName = '_Total'
    AND COALESCE(b.InstanceName, '-') LIKE COALESCE(b.InstanceName, '-')
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
    and a.CounterValue <> 0 -- about half of the entries return as 0, filter these out
ORDER BY Collected;
SELECT 'SQL Process Stats:' AS [Info], 'SQL Process Utilisation > 50% if Processor % > 80%' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, COALESCE(b.InstanceName, '-') AS Process
, CAST(a.CounterValue AS DECIMAL(10, 5)) AS PercentProcessorTime
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = 'Process'
    AND b.CounterName = '% Processor Time'
    AND b.InstanceName IN ('sqlservr','sqlagent')
    AND a.CounterValue <> 0
    AND COALESCE(b.InstanceName, '-') LIKE COALESCE(b.InstanceName, '-')
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;
SELECT 'Other Process Stats:' AS [Info], 'Processes with > 50% CPU Utilisation' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, COALESCE(b.InstanceName, '-') AS Process
, CAST(a.CounterValue AS DECIMAL(10, 5)) AS PercentProcessorTime
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = 'Process'
    AND b.CounterName = '% Processor Time'
    AND b.InstanceName NOT IN ('sqlservr','sqlagent','_Total','Idle')
    AND a.CounterValue > 50
    AND COALESCE(b.InstanceName, '-') LIKE COALESCE(b.InstanceName, '-')
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;

-- Get Memory Stats:
SELECT 'Memory Available Stats:' AS [Info], 'Available MB should be > 5% of physical RAM' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, CAST(a.CounterValue AS FLOAT)/1024/1024 AS MBytesAvailable
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = 'Memory'
    AND b.CounterName = 'Available Bytes'
    --AND a.CounterValue <> 0
    --AND b.InstanceName <> '_Total'
    AND COALESCE(b.InstanceName, '-') LIKE COALESCE(b.InstanceName, '-')
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;
SELECT 'Server Page Faults/sec Stats:' AS [Info], 'Server Page Faults should be < 300' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, CAST(a.CounterValue AS FLOAT) AS PageFaultsPerSec
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = 'Memory'
    AND b.CounterName = 'Page Faults/sec'
    AND a.CounterValue <> 0
    --AND b.InstanceName <> '_Total'
    AND COALESCE(b.InstanceName, '-') LIKE COALESCE(b.InstanceName, '-')
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;
SELECT 'Server Pages/sec Stats:' AS [Info], 'Server Page/Sec should be < 1000' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, CAST(a.CounterValue AS FLOAT) AS PagesPerSec
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = 'Memory'
    AND b.CounterName = 'Pages/sec'
    AND a.CounterValue <> 0
    --AND b.InstanceName <> '_Total'
    AND COALESCE(b.InstanceName, '-') LIKE COALESCE(b.InstanceName, '-')
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;
SELECT 'SQL Process Page Faults/sec Stats:' AS [Info], 'Ideally SQL Process Page Faults/sec < 50' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, CAST(a.CounterValue AS FLOAT) AS PageFaultsPerSec
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = 'Memory'
    AND b.CounterName = 'Page Faults/sec'
    AND b.InstanceName = 'sqlservr'
    --AND a.CounterValue <> 0
    --AND b.InstanceName <> '_Total'
    AND COALESCE(b.InstanceName, '-') LIKE COALESCE(b.InstanceName, '-')
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;
SELECT 'SQL Process Page Faults/sec Stats:' AS [Info], 'Ideally SQL Process Pages/sec < 50' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, CAST(a.CounterValue AS FLOAT) AS PageFaultsPerSec
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = 'Memory'
    AND b.CounterName = 'Pages/sec'
    AND b.InstanceName = 'sqlservr'
    --AND a.CounterValue <> 0
    --AND b.InstanceName <> '_Total'
    AND COALESCE(b.InstanceName, '-') LIKE COALESCE(b.InstanceName, '-')
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;
-- Get Network Stats:
SELECT 'Network Interface Stats:' AS [Info], 'Check if Network is saturated.' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, COALESCE(b.InstanceName, '-') AS NetworkInterface
, CAST(a.CounterValue AS FLOAT) AS BytesTotalPerSec
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = 'Network Interface'
    AND b.CounterName = 'Bytes Total/sec'
    AND a.CounterValue <> 0
    --AND b.InstanceName <> '_Total'
    AND COALESCE(b.InstanceName, '-') LIKE COALESCE(b.InstanceName, '-')
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;

-- Get User connections:
SELECT 'User Connection Stats:' AS [Info], '-' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, CAST(a.CounterValue AS DECIMAL(10, 0)) AS UserConnections
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = (
SELECT value
    FROM EIT_DBA.dbo.EIT_monitoring_config
    WHERE configuration = 'dba_trend_instance'
) + ':General Statistics' COLLATE Latin1_General_CI_AS -- default instance is SQLServer, a named instane e.g. TEST would be MSSQL$TEST
    AND b.CounterName = 'User Connections'
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;
-- Get PLE stats:
SELECT 'Page Life Expectancy Stats:' AS [Info], 'Ideally as high as possible > 1000.' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, CAST(a.CounterValue AS DECIMAL(10, 0)) AS PageLifeExpectancySeconds
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = (
SELECT value
    FROM EIT_DBA.dbo.EIT_monitoring_config
    WHERE configuration = 'dba_trend_instance'
) + ':Buffer Manager' COLLATE Latin1_General_CI_AS -- default instance is SQLServer, a named instane e.g. TEST would be MSSQL$TEST
    AND b.CounterName = 'Page life expectancy'
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;
-- Memory Grants Pending:'
SELECT 'Memory Grants Outstanding Stats:' AS [Info], 'Ideally = 0, otherwise instance may need more memory.' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, CAST(a.CounterValue AS DECIMAL(10, 0)) AS MemoryGrantsPending
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = (
SELECT value
    FROM EIT_DBA.dbo.EIT_monitoring_config
    WHERE configuration = 'dba_trend_instance'
) + ':Memory Manager' COLLATE Latin1_General_CI_AS -- default instance is SQLServer, a named instane e.g. TEST would be MSSQL$TEST
    AND b.CounterName = 'Memory Grants Pending'
    AND a.CounterValue <> 0
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;
-- Get Batch Requests:
SELECT 'Batch Request Stats:' AS [Info], '-' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, CAST(a.CounterValue AS DECIMAL(10, 0)) AS BatchRequestsPerSec
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = (
SELECT value
    FROM EIT_DBA.dbo.EIT_monitoring_config
    WHERE configuration = 'dba_trend_instance'
) + ':SQL Statistics' COLLATE Latin1_General_CI_AS -- default instance is SQLServer, a named instane e.g. TEST would be MSSQL$TEST
    AND b.CounterName = 'Batch Requests/sec'
    AND a.CounterValue <> 0
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;
-- SQL Compilations/sec:
SELECT 'SQL Compilations/sec Stats:' AS [Info], 'If SQL Compilations/sec > 10% of Batch Request, there may not be enough memory to cache plans.' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, CAST(a.CounterValue AS DECIMAL(10, 0)) AS SQLCompilationsPerSec
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = (
SELECT value
    FROM EIT_DBA.dbo.EIT_monitoring_config
    WHERE configuration = 'dba_trend_instance'
) + ':SQL Statistics' COLLATE Latin1_General_CI_AS -- default instance is SQLServer, a named instane e.g. TEST would be MSSQL$TEST
    AND b.CounterName = 'SQL Compilations/sec'
    AND a.CounterValue <> 0
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;
-- SQL Recompliations/sec:
SELECT 'SQL Re-Compilations/sec Stats:' AS [Info], 'Compare with SQL Compilations/sec - if too many then not enough plan reuse.' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, CAST(a.CounterValue AS DECIMAL(10, 0)) AS SQLReCompilationsPerSec
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = (
SELECT value
    FROM EIT_DBA.dbo.EIT_monitoring_config
    WHERE configuration = 'dba_trend_instance'
) + ':SQL Statistics' COLLATE Latin1_General_CI_AS -- default instance is SQLServer, a named instane e.g. TEST would be MSSQL$TEST
    AND b.CounterName = 'SQL Re-Compilations/sec'
    AND a.CounterValue <> 0
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;
-- Cache Hit Ratio:
SELECT 'Cache Hit Ratio Stats:' AS [Info], 'Ideally as high as possible.' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, COALESCE(b.InstanceName, '-') AS CounterName
, CAST(a.CounterValue AS DECIMAL(10, 5)) AS PlanCacheHitRatio
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = (
SELECT value
    FROM EIT_DBA.dbo.EIT_monitoring_config
    WHERE configuration = 'dba_trend_instance'
) + ':Plan Cache' COLLATE Latin1_General_CI_AS -- default instance is SQLServer, a named instane e.g. TEST would be MSSQL$TEST
    AND b.CounterName = 'Cache Hit Ratio'
    --AND b.InstanceName <> '_Total'
    AND COALESCE(b.InstanceName, '-') LIKE COALESCE(b.InstanceName, '-')
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;
-- AvgDiskSecPerRead
SELECT 'Avg. Disk sec/Read Stats:' AS [Info], 'Ideally < 0.25.' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, COALESCE(b.InstanceName, '-') AS DiskName
, CAST(a.CounterValue AS DECIMAL(10, 5)) AS AvgDiskSecPerRead
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = 'LogicalDisk'
    AND b.CounterName = 'Avg. Disk sec/Read'
    AND b.InstanceName <> '_Total'
    AND b.InstanceName NOT LIKE 'Harddisk%'
    AND a.CounterValue <> 0
    AND COALESCE(b.InstanceName, '-') LIKE COALESCE(b.InstanceName, '-')
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;
-- AvgDiskSecPerWrite
SELECT 'Avg. Disk sec/Write Stats:' AS [Info], 'Ideally < 0.25' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, COALESCE(b.InstanceName, '-') AS DiskName
, CAST(a.CounterValue AS DECIMAL(10, 5)) AS AvgDiskSecPerWrite
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = 'LogicalDisk'
    AND b.CounterName = 'Avg. Disk sec/Write'
    AND b.InstanceName <> '_Total'
    AND b.InstanceName NOT LIKE 'Harddisk%'
    AND a.CounterValue <> 0
    AND COALESCE(b.InstanceName, '-') LIKE COALESCE(b.InstanceName, '-')
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;
--Active Transactions
SELECT 'Active Transactions:' AS [Info], 'Active Transaction count on Database.' AS [Check];
SELECT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, COALESCE(b.InstanceName, '-') AS DatabaseName
, CAST(a.CounterValue AS DECIMAL(10, 5)) AS ActiveTransactions
FROM dbo.CounterData a
, dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = (
SELECT value
    FROM EIT_DBA.dbo.EIT_monitoring_config
    WHERE configuration = 'dba_trend_instance'
) + ':Databases' COLLATE Latin1_General_CI_AS -- default instance is SQLServer, a named instane e.g. TEST would be MSSQL$TEST
    AND b.CounterName = 'Active Transactions'
    AND b.InstanceName <> '_Total'
    AND a.CounterValue <> 0
    AND b.InstanceName = @review_database
    AND COALESCE(b.InstanceName, '-') LIKE COALESCE(b.InstanceName, '-')
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
ORDER BY Collected;
-- ******************************
-- ** DB Stats
-- ******************************
-- Get Data File Size Stats:
SELECT 'Data File Size:' AS [Info], 'Ideally stable.' AS [Check];
SELECT DISTINCT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, COALESCE(b.InstanceName, '-') AS DatabaseName
, CASE
WHEN CAST(MAX(a.CounterValue) / 1024 AS BIGINT) < 1
THEN 1
ELSE CAST(MAX(a.CounterValue) / 1024 AS BIGINT)
END AS DataFileSizeMB
FROM EIT_DBA.dbo.CounterData a
, EIT_DBA.dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = (
SELECT value
    FROM EIT_DBA.dbo.EIT_monitoring_config
    WHERE configuration = 'dba_trend_instance'
) + ':Databases' COLLATE Latin1_General_CI_AS -- default instance is SQLServer, a named instane e.g. TEST would be MSSQL$TEST
    AND b.CounterName = 'Data File(s) Size (KB)'
    AND b.InstanceName = @review_database
    AND COALESCE(b.InstanceName, '-') LIKE COALESCE(b.InstanceName, '-')
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
GROUP BY COALESCE(b.InstanceName, '-')
,CAST(a.CounterDateTime AS VARCHAR(19))
ORDER BY Collected;
-- Get Log File Size Stats:
SELECT 'Log File Size:' AS [Info], 'Ideally stable.' AS [Check];
SELECT DISTINCT CAST(a.CounterDateTime AS VARCHAR(19)) AS Collected
, COALESCE(b.InstanceName, '-') AS DatabaseName
, CASE
WHEN CAST(MAX(a.CounterValue) / 1024 AS BIGINT) < 1
THEN 1
ELSE CAST(MAX(a.CounterValue) / 1024 AS BIGINT)
END AS LogFileSizeMB
FROM EIT_DBA.dbo.CounterData a
, EIT_DBA.dbo.CounterDetails b
WHERE 1 = 1
    AND a.CounterID = b.CounterID
    AND b.ObjectName = (
SELECT value
    FROM EIT_DBA.dbo.EIT_monitoring_config
    WHERE configuration = 'dba_trend_instance'
) + ':Databases' COLLATE Latin1_General_CI_AS -- default instance is SQLServer, a named instane e.g. TEST would be MSSQL$TEST
    AND b.CounterName = 'Log File(s) Size (KB)'
    AND b.InstanceName = @review_database
    AND COALESCE(b.InstanceName, '-') LIKE COALESCE(b.InstanceName, '-')
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) >= @review_start_datetime
    AND CONVERT(DATETIME, CONVERT(CHAR(23), a.CounterDateTime), 121) <= @review_end_datetime
GROUP BY COALESCE(b.InstanceName, '-')
,CAST(a.CounterDateTime AS VARCHAR(19))
ORDER BY Collected;
-- Get Auto Growths / Shrinks:
SELECT 'Auto Grow / Shrink Events:' AS [Info], 'Ideally stable.' AS [Check];
SELECT start_time
, database_name
, event_name
, filename
, duration
FROM EIT_trend_default_trace
WHERE event_name IN (
'Data File Auto Grow'
,'Data File Auto Shrink'
,'Log File Auto Grow'
,'Log File Auto Shrink'
)
    AND database_name = @review_database
    AND start_time >= @review_start_datetime
    AND start_time <= @review_end_datetime
ORDER BY start_time;
-- Analyse Database I/O
SELECT 'Database I/O:' AS [Info], 'Ideally stable.' AS [Check];
SELECT *
FROM [dbo].[EIT_trend_database_io]
WHERE dttm BETWEEN @review_start_datetime AND @review_end_datetime
    AND d_name = @review_database
ORDER BY dttm;
-- Analyze Waits Stats
SELECT 'Wait Stats:' AS [Info];
SELECT *
FROM [dbo].[EIT_trend_waits]
WHERE dttm BETWEEN @review_start_datetime AND @review_end_datetime
    AND [wait_type] NOT IN (
        N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR',
        N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH',
        N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
        N'CHKPT', N'CLR_AUTO_EVENT',
        N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
 
        -- Maybe uncomment these four if you have mirroring issues
        N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE',
        N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD',
 
        N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC', N'FSAGENT',
        N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
 
        -- Maybe uncomment these six if you have AG issues
        N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
        N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE',
        N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
 
        N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP',
        N'LOGMGR_QUEUE', N'MEMORY_ALLOCATION_EXT',
        N'ONDEMAND_TASK_QUEUE',
        N'PREEMPTIVE_XE_GETTARGETSTATE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED',
        N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', N'QDS_ASYNC_QUEUE',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
        N'QDS_SHUTDOWN_QUEUE', N'REDO_THREAD_PENDING_WORK',
        N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
        N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH',
        N'SLEEP_DBSTARTUP', N'SLEEP_DCOMSTARTUP',
        N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP',
        N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT',
        N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
        N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS',
        N'WAITFOR', N'WAITFOR_TASKSHUTDOWN',
        N'WAIT_XTP_RECOVERY',
        N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
        N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')
ORDER BY waiting_tasks_count desc;
-- Analyze Alerts:
SELECT 'SQL Alerts:' AS [Info];
SELECT *
FROM [dbo].[EIT_trend_alerts]
WHERE dttm BETWEEN @review_start_datetime AND @review_end_datetime
ORDER BY dttm;
-- Analyse Blocked Processes:
SELECT 'Blocked Processes:' AS [Info];
SELECT *
FROM [dbo].[EIT_trend_blocked_processes]
WHERE dttm BETWEEN @review_start_datetime AND @review_end_datetime
ORDER BY dttm;

-- Analyse Deadlocked Processes:
SELECT 'Deadlocked Processes:' AS [Info];
SELECT *
FROM [dbo].[EIT_trend_deadlock_process]
WHERE dttm BETWEEN @review_start_datetime AND @review_end_datetime
ORDER BY dttm;

-- Analyse Job Changes:
SELECT 'Job Created/Modified:' AS [Info];
SELECT *
FROM [dbo].[EIT_trend_job_changes]
WHERE date_created BETWEEN @review_start_datetime AND @review_end_datetime
    OR date_modified BETWEEN @review_start_datetime AND @review_end_datetime
ORDER BY dttm;

-- Analyse Job Failures:
SELECT 'Job Failures:' AS [Info];
SELECT *
FROM [dbo].[EIT_trend_job_failure_history]
WHERE dttm BETWEEN @review_start_datetime AND @review_end_datetime
ORDER BY dttm;

-- Analyse Long Running Query:
SELECT 'Long Running Queries:' AS [Info];
SELECT *
FROM [dbo].[EIT_trend_long_running_query]
WHERE start_time BETWEEN @review_start_datetime AND @review_end_datetime
ORDER BY dttm;

-- Analyse Long Running Query:
SELECT 'Long Running Transactions:' AS [Info];
SELECT *
FROM [dbo].[EIT_trend_long_running_transaction]
WHERE dttm BETWEEN @review_start_datetime AND @review_end_datetime
ORDER BY dttm;

-- Analyze Errorlogs
SELECT 'Error Log Messages:' AS [Info];
SELECT LogDate, ProcessInfo, LogText
FROM [dbo].[EIT_trend_errorlog]
WHERE LogDate BETWEEN @review_start_datetime AND @review_end_datetime
ORDER BY dttm;

-- Analyze SQL Agent Errorlogs
SELECT 'SQL Agent Error Log Messages:' AS [Info];
SELECT LogDate, ProcessInfo, LogText
FROM [dbo].[EIT_trend_sqlagentlog]
WHERE LogDate BETWEEN @review_start_datetime AND @review_end_datetime
ORDER BY dttm;

-- Analyze Default Trace
SELECT 'Default Trace Messages:' AS [Info];
SELECT *
FROM [dbo].[EIT_trend_default_trace]
WHERE start_time BETWEEN @review_start_datetime AND @review_end_datetime
ORDER BY dttm;

-- Get Event Log info:
SELECT 'Windows Application Event Logs:' AS [Info];
SELECT *
FROM [dbo].[EIT_trend_os_event_log_application]
WHERE CONVERT(datetime,STUFF(STUFF(STUFF(SUBSTRING(timegenerated,1,14), 9, 0, ' '), 12, 0, ':'), 15, 0, ':')) >= @review_start_datetime
    AND CONVERT(datetime,STUFF(STUFF(STUFF(SUBSTRING(timegenerated,1,14), 9, 0, ' '), 12, 0, ':'), 15, 0, ':')) <= @review_end_datetime
ORDER BY dttm;

SELECT 'Windows System Event Logs:' AS [Info];
SELECT *
FROM [dbo].[EIT_trend_os_event_log_system]
WHERE CONVERT(datetime,STUFF(STUFF(STUFF(SUBSTRING(timegenerated,1,14), 9, 0, ' '), 12, 0, ':'), 15, 0, ':')) >= @review_start_datetime
    AND CONVERT(datetime,STUFF(STUFF(STUFF(SUBSTRING(timegenerated,1,14), 9, 0, ' '), 12, 0, ':'), 15, 0, ':')) <= @review_end_datetime
ORDER BY dttm;