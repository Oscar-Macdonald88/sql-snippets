USE [SQLMSP]
GO

/****** Object:  UserDefinedFunction [report].[tvfReportSummary]    Script Date: 9/6/2023 1:53:12 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [report].[tvfReportSummary] (@CustomerCode nvarchar(128), @StartDate date, @EndDate date)
RETURNS TABLE
AS
RETURN (

-- Report Summary
-- 27/08/2012 - Version 1.0 - KN - Created
-- 19/09/2012 - Version 1.1 - KN - Remove cte from UserDatabases, add CASE to ReportQuery
-- 26/11/2012 - Version 1.1 - KN - DataFileSizeMB was renamed to DatabasesDataFileSizeMB
-- 17/05/2013 - Version 1.2 - KN - Coded to only report np
-- 07/08/2014 - Version 1.3 - KH - Refactored code
-- 30/12/2015 - Version 1.4 - KH - Refactored for combined reports.
-- 26/05/2022 - Version 1.5 - KH - Updated to use SQLMSP tables.

-- BackupFailures
-- UserDatabases
-- DatabaseCreated
-- DatabaseRemoved
-- ErrorlogErrors
-- LinkedServerModified
-- LinkedServerRemoved
-- LoginCreated
-- LoginFailures
-- LoginRemoved
-- JobCreated
-- JobFailures
-- JobRemoved
-- SQLServerRestarts
-- SQLInstances
-- ReportQuery

-- Test Code
--DECLARE @CustomerCode nvarchar(1024)
--DECLARE @StartDate date
--DECLARE @EndDate date
--DECLARE @ReportEnvParameter char(2)

--SET @CustomerCode = 'UNIC'
--SET @StartDate = '2022-04-01'
--SET @EndDate = '2022-04-30'
--SET @ReportEnvParameter = 'p'

--********************
--** BackupFailures  *
--********************
-- BackupFailures Table

-- BackupFailures Query
WITH BackupFailures AS (
	SELECT b.CustomerCode AS Client 
		,b.InstanceName AS SQLInstance
		,'BackupFailures' AS Report
		, SUM(b.Occurrences) AS Occurrences
	FROM [report].[vBackupFailuresAggregate] b
	JOIN [msp].[vInventory] i
	ON b.CustomerId = i.CustomerId AND b.InstanceId = i.InstanceId
	WHERE 1=1
		AND i.IsActive = 1
		AND b.CustomerCode = @CustomerCode
		AND b.Collected BETWEEN @StartDate AND @EndDate
	
	GROUP BY b.CustomerCode,b.InstanceName
),

--SELECT * FROM @BackupFailures

--********************
--** UserDatabases   *
--********************
-- UserDatabases Table
UserDatabases AS (
	SELECT d.CustomerCode AS Client 
		,d.InstanceName AS SQLInstance
		,'UserDatabases' AS Report
		, TrendCount AS Occurrences
		,d.Collected
	FROM [report].[vDatabaseCount] d
	JOIN [msp].[vInventory] i
	ON d.CustomerId = i.CustomerId AND d.InstanceId = i.InstanceId
	WHERE 1=1
		--AND d.DatabaseName NOT IN ('_Total','master','model','msdb','mssqlsystemresource','tempdb','EIT_DBA')
		AND d.CustomerCode = @CustomerCode
	
		AND i.IsActive = 1
		AND d.Collected > DATEADD(d,-2,@EndDate)
	--GROUP BY d.CustomerCode, d.InstanceName, d.Last_Detected 
),

--INSERT INTO @UserDatabases (Client,SQLInstance,Report,Occurrences)
--SELECT Client, SQLInstance, Report, Occurrences
--FROM 
--	UserDatabases_CTE AS a
--WHERE a.Collected = (SELECT MAX(b.Collected) FROM UserDatabases_CTE AS b WHERE a.Client = b.Client AND a.SqlInstance = b.SqlInstance)

--SELECT * FROM @UserDatabases 

--********************
--** DatabaseCreated *
--********************
-- DatabaseCreated Table
DatabaseCreated AS
(
	SELECT d.CustomerCode AS Client
		,d.InstanceName AS SqlInstance
		,'DatabaseCreated' AS Report
		,COUNT(*) AS Occurrences
	FROM [report].[vDatabaseCreated] d
	JOIN [msp].[vInventory] i
	ON d.CustomerId = i.CustomerId AND d.InstanceId = i.InstanceId
	WHERE 1=1
	AND d.CustomerCode = @CustomerCode
	AND d.Collected BETWEEN @StartDate AND @EndDate

	GROUP BY d.CustomerCode,d.InstanceName
),

--SELECT * FROM @DatabaseCreated

--********************
--** DatabaseRemoved *
--********************
-- DatabaseRemoved Table
DatabaseRemoved AS
(
	SELECT d.CustomerCode AS Client
		,d.InstanceName AS SqlInstance
		,'DatabaseRemoved' AS Report
		,COUNT(*) AS Occurrences
	FROM [report].[vDatabaseRemoved] d
	JOIN [msp].[vInventory] i
	ON d.CustomerId = i.CustomerId AND d.InstanceId = i.InstanceId
	WHERE 1=1
	AND d.CustomerCode = @CustomerCode
	AND d.Collected BETWEEN @StartDate AND @EndDate

	GROUP BY d.CustomerCode,d.InstanceName
),

--SELECT * FROM @DatabaseRemoved

--********************
--** ErrorlogErrors  *
--********************
-- ErrorlogErrors Table
ErrorlogErrors AS
(
	SELECT d.CustomerCode AS Client
		,d.InstanceName AS SqlInstance
		,'ErrorlogErrors' AS Report
		,SUM(Occurrences) AS Occurrences
	FROM [report].[vErrorlogAggregate] d
	JOIN [msp].[vInventory] i
	ON d.CustomerId = i.CustomerId AND d.InstanceId = i.InstanceId
	WHERE 1=1
	AND d.CustomerCode = @CustomerCode
	AND d.Collected BETWEEN @StartDate AND @EndDate

	GROUP BY d.CustomerCode,d.InstanceName
),

--SELECT * FROM @ErrorlogErrors

--*************************
--** LinkedServerModified *
--*************************
-- LinkedServerModified Table
LinkedServerModified AS
(
	SELECT d.CustomerCode AS Client
		,d.InstanceName AS SqlInstance
		,'LinkedServerModified' AS Report
		,COUNT(*) AS Occurrences
	FROM [report].[vLinkedServerModified] d
	JOIN [msp].[vInventory] i
	ON d.CustomerId = i.CustomerId AND d.InstanceId = i.InstanceId
	WHERE 1=1
	AND d.CustomerCode = @CustomerCode
	AND d.Collected BETWEEN @StartDate AND @EndDate

	GROUP BY d.CustomerCode,d.InstanceName
),

--SELECT * FROM @LinkedServerModified

--*************************
--** LinkedServerRemoved  *
--*************************
-- LinkedServerRemoved Table
LinkedServerRemoved AS
(
	SELECT d.CustomerCode AS Client
		,d.InstanceName AS SqlInstance
		,'LinkedServerRemoved' AS Report
		,COUNT(*) AS Occurrences
	FROM [report].[vLinkedServerModified] d
	JOIN [msp].[vInventory] i
	ON d.CustomerId = i.CustomerId AND d.InstanceId = i.InstanceId
	WHERE 1=1
	AND d.CustomerCode = @CustomerCode
	AND d.Collected BETWEEN @StartDate AND @EndDate

	GROUP BY d.CustomerCode,d.InstanceName
),

--SELECT * FROM @LinkedServerRemoved

--*************************
--** LoginCreated *
--*************************
-- LoginCreated Table
LoginCreated AS
(
	SELECT d.CustomerCode AS Client
		,d.InstanceName AS SqlInstance
		,'LoginCreated' AS Report
		,SUM(Occurrences) AS Occurrences
	FROM [report].[vLoginCreatedAggregate] d
	JOIN [msp].[vInventory] i
	ON d.CustomerId = i.CustomerId AND d.InstanceId = i.InstanceId
	WHERE 1=1
	AND d.CustomerCode = @CustomerCode
	AND d.Collected BETWEEN @StartDate AND @EndDate

	GROUP BY d.CustomerCode,d.InstanceName
),

--SELECT * FROM @LoginCreated

--******************
--** LoginFailures *
--******************
-- LoginFailures Table
LoginFailures AS
(
	SELECT d.CustomerCode AS Client
		,d.InstanceName AS SqlInstance
		,'LoginFailures' AS Report
		,SUM(Occurrences) AS Occurrences
	FROM [report].[vLoginFailuresAggregate] d
	JOIN [msp].[vInventory] i
	ON d.CustomerId = i.CustomerId AND d.InstanceId = i.InstanceId
	WHERE 1=1
	AND d.CustomerCode = @CustomerCode
	AND d.Collected BETWEEN @StartDate AND @EndDate

	GROUP BY d.CustomerCode,d.InstanceName
),

--SELECT * FROM @LoginFailures

--******************
--** LoginRemoved *
--******************
-- LoginRemoved Table
LoginRemoved AS
(
	SELECT d.CustomerCode AS Client
		,d.InstanceName AS SqlInstance
		,'LoginRemoved' AS Report
		,SUM(Occurrences) AS Occurrences
	FROM [report].[vLoginRemovedAggregate] d
	JOIN [msp].[vInventory] i
	ON d.CustomerId = i.CustomerId AND d.InstanceId = i.InstanceId
	WHERE 1=1
	AND d.CustomerCode = @CustomerCode
	AND d.Collected BETWEEN @StartDate AND @EndDate

	GROUP BY d.CustomerCode,d.InstanceName
),

----SELECT * FROM @LoginRemoved

--***************
--** JobCreated *
--***************
-- JobCreated Table
JobCreated AS
(
	SELECT d.CustomerCode AS Client
		,d.InstanceName AS SqlInstance
		,'JobCreated' AS Report
		,SUM(Occurrences) AS Occurrences
	FROM [report].[vJobCreatedAggregate] d
	JOIN [msp].[vInventory] i
	ON d.CustomerId = i.CustomerId AND d.InstanceId = i.InstanceId
	WHERE 1=1
	AND d.CustomerCode = @CustomerCode
	AND d.Collected BETWEEN @StartDate AND @EndDate

	GROUP BY d.CustomerCode,d.InstanceName
),

--SELECT * FROM @JobCreated

--****************
--** JobFailures *
--****************
-- JobFailures Table
JobFailures AS
(
	SELECT d.CustomerCode AS Client
		,d.InstanceName AS SqlInstance
		,'JobFailures' AS Report
		,SUM(Occurrences) AS Occurrences
	FROM [report].[vJobFailuresAggregate] d
	JOIN [msp].[vInventory] i
	ON d.CustomerId = i.CustomerId AND d.InstanceId = i.InstanceId
	WHERE 1=1
	AND d.CustomerCode = @CustomerCode
	AND d.Collected BETWEEN @StartDate AND @EndDate

	GROUP BY d.CustomerCode,d.InstanceName
),

--SELECT * FROM @JobFailures

--****************
--** JobRemoved  *
--****************
-- JobRemoved Table
JobRemoved AS
(
	SELECT d.CustomerCode AS Client
		,d.InstanceName AS SqlInstance
		,'JobRemoved' AS Report
		,SUM(Occurrences) AS Occurrences
	FROM [report].[vJobRemovedAggregate] d
	JOIN [msp].[vInventory] i
	ON d.CustomerId = i.CustomerId AND d.InstanceId = i.InstanceId
	WHERE 1=1
	AND d.CustomerCode = @CustomerCode
	AND d.Collected BETWEEN @StartDate AND @EndDate

	GROUP BY d.CustomerCode,d.InstanceName
),

--SELECT * FROM @JobRemoved

--***********************
--** SQLServerRestarts  *
--***********************
-- SQLServerRestarts Table
SQLServerRestarts AS (
	SELECT d.CustomerCode AS Client
		,d.InstanceName AS SqlInstance
		,'SQLServerRestarts' AS Report
		,COUNT(*) AS Occurrences
	FROM [report].[vSQLServerRestarts] d
	JOIN [msp].[vInventory] i
	ON d.CustomerId = i.CustomerId AND d.InstanceId = i.InstanceId
	WHERE 1=1
	AND d.CustomerCode = @CustomerCode
	AND d.LastRestart BETWEEN @StartDate AND @EndDate

	GROUP BY d.CustomerCode,d.InstanceName
),

--SELECT * FROM @SQLServerRestarts

--********************
--** SQLInstances    *
--********************
-- SQLInstances Table
SQLInstances AS
(
	SELECT [CustomerCode] AS Client
      ,[InstanceName] AS SQLInstance
	  ,EnvironmentName 
	FROM [msp].[vInventory]
	WHERE CustomerCode = @CustomerCode
	AND IsActive = 1

)

--SELECT * FROM @SQLInstances

--*******************
--** ReportQuery    *
--*******************

SELECT a.SQLInstance
,EnvironmentName
,COALESCE((SELECT Occurrences FROM BackupFailures b WHERE a.SQLInstance = b.SQLInstance),0) AS 'Backup Failures' 
,COALESCE((SELECT Occurrences FROM UserDatabases b WHERE a.SQLInstance = b.SQLInstance AND Collected = (SELECT MAX(b.Collected) FROM UserDatabases AS b WHERE a.Client = b.Client AND a.SqlInstance = b.SqlInstance)),0) AS 'User Databases'
,COALESCE((SELECT Occurrences FROM DatabaseCreated b WHERE a.SQLInstance = b.SQLInstance),0) AS 'Database Created'
,COALESCE((SELECT Occurrences FROM DatabaseRemoved b WHERE a.SQLInstance = b.SQLInstance),0) AS 'Database Removed'
,COALESCE((SELECT Occurrences FROM ErrorlogErrors b WHERE a.SQLInstance = b.SQLInstance),0) AS 'Errorlog Errors'
,COALESCE((SELECT Occurrences FROM LinkedServerModified b WHERE a.SQLInstance = b.SQLInstance),0) AS 'Linked Server Modified'
,COALESCE((SELECT Occurrences FROM LinkedServerRemoved b WHERE a.SQLInstance = b.SQLInstance),0) AS 'Linked Server Removed'
,COALESCE((SELECT Occurrences FROM LoginCreated b WHERE a.SQLInstance = b.SQLInstance),0) AS 'Login Created'
,COALESCE((SELECT Occurrences FROM LoginRemoved b WHERE a.SQLInstance = b.SQLInstance),0) AS 'Login Removed'
,COALESCE((SELECT Occurrences FROM LoginFailures b WHERE a.SQLInstance = b.SQLInstance),0) AS 'Login Failures'
,COALESCE((SELECT Occurrences FROM JobCreated b WHERE a.SQLInstance = b.SQLInstance),0) AS 'Job Created'
,COALESCE((SELECT Occurrences FROM JobRemoved b WHERE a.SQLInstance = b.SQLInstance),0) AS 'Job Removed'
,COALESCE((SELECT Occurrences FROM JobFailures b WHERE a.SQLInstance = b.SQLInstance),0) AS 'Job Failures'
,COALESCE((SELECT Occurrences FROM SQLServerRestarts b WHERE a.SQLInstance = b.SQLInstance),0) AS 'SQL Server Restarts'
FROM SQLInstances a
--ORDER BY a.SQLInstance
)
GO