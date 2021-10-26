--Basic system information script
 
DECLARE @xp_msver TABLE ([idx] [int] NULL,[c_name] [varchar](100) NULL,[int_val] [float] NULL,[c_val] [varchar](128) NULL)
 
INSERT INTO @xp_msver EXEC ('[master]..[xp_msver]');
 
WITH [ProcessorInfo] AS (SELECT ([cpu_count] / [hyperthread_ratio]) AS 'Physical CPUs',
CASE WHEN hyperthread_ratio = cpu_count THEN cpu_count/2 ELSE (CASE WHEN (([cpu_count] - [hyperthread_ratio]) / ([cpu_count] / [hyperthread_ratio]) != 0)THEN ([cpu_count] - [hyperthread_ratio]) / ([cpu_count] / [hyperthread_ratio])ELSE 1 END)END AS 'Physical cores',
CASE WHEN hyperthread_ratio = cpu_count THEN cpu_count/2 ELSE (CASE WHEN (([cpu_count] / [hyperthread_ratio]) * (([cpu_count] - [hyperthread_ratio]) / ([cpu_count] / [hyperthread_ratio])) != 0)THEN ([cpu_count] / [hyperthread_ratio]) * (([cpu_count] - [hyperthread_ratio]) / ([cpu_count] / [hyperthread_ratio]))ELSE [cpu_count] END)END AS 'Total Physical cores',
[cpu_count] AS 'Total Threads',
(SELECT [c_val]FROM @xp_msver WHERE [c_name] = 'Platform') AS 'cpu_category' FROM [sys].[dm_os_sys_info])
 
SELECT SERVERPROPERTY('ServerName') AS 'SQLServerName', CASE RIGHT(SUBSTRING(@@VERSION, CHARINDEX('Windows NT', @@VERSION), 14), 3)WHEN '5.0' THEN 'Windows 2000'WHEN '5.1' THEN 'Windows XP'WHEN '5.2' THEN 'Windows Server 2003'WHEN '6.0' THEN 'Windows Server 2008'WHEN '6.1' THEN 'Windows Server 2008 R2'WHEN '6.2' THEN 'Windows Server 2012'WHEN '6.3' THEN 'Windows Server 2016'ELSE SERVERPROPERTY('ServerName')END AS 'WindowsVersionBuild', 
[Physical CPUs],[Physical cores],[Total Physical cores], [Total Threads], (SELECT int_val FROM @xp_msver WHERE c_name = 'PhysicalMemory') AS 'Server RAM MB',(SELECT value FROM sys.configurations WHERE name = 'max server memory (MB)') AS 'SQL Server RAM Allocation MB',((SELECT int_val FROM @xp_msver WHERE c_name = 'PhysicalMemory')-(SELECT (CONVERT(INT,value)) FROM sys.configurations WHERE name = 'max server memory (MB)')) AS 'Windows RAM Allocation MB', 
CASE LEFT(CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion')),4) WHEN '8.00' THEN 'SQL Server 2000'WHEN '9.00' THEN 'SQL Server 2005'WHEN '10.0' THEN 'SQL Server 2008'WHEN '10.5' THEN 'SQL Server 2008 R2'WHEN '11.0' THEN 'SQL Server 2012'WHEN '12.0' THEN 'SQL Server 2014'WHEN '13.0' THEN 'SQL Server 2016'WHEN '14.0' THEN 'SQL Server 2017'ELSE LEFT(CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion')),4)END AS 'SQLVersionBuild', SERVERPROPERTY('Edition') AS 'SQLEdition', getdate() AS 'LastSeen' FROM [ProcessorInfo]
 
SELECT Param, TextValue FROM SSLDBA.dbo.tbl_Param WHERE Param IN ('SQLData', 'SQLReportsDir', 'SQLLogDumps', 'SQLLogs', 'SQLDataDumps', 'DropFolderDir', 'TemplateOverrideRequired', 'SLALevel', '24x7')
 
EXEC xp_fixeddrives