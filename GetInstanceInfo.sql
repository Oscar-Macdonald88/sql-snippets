-- press Ctrl + Shift + E to Execute SQL
DECLARE @ProductVersion NVARCHAR(20);
DECLARE @Create_Date AS SMALLDATETIME;
SET @ProductVersion = CONVERT(NVARCHAR(20), SERVERPROPERTY('ProductVersion'));
SELECT @Create_Date = create_date
FROM sys.server_principals
WHERE sid = 0x010100000000000512000000;
SELECT '[Client Name]' AS [ClientName],
       'SQL Server '+CASE
                         WHEN @ProductVersion LIKE '9.%'
                         THEN '2005'
                         WHEN @ProductVersion LIKE '10.0%'
                         THEN '2008'
                         WHEN @ProductVersion LIKE '10.5%'
                         THEN '2008 R2'
                         WHEN @ProductVersion LIKE '11.%'
                         THEN '2012'
                         WHEN @ProductVersion LIKE '12%'
                         THEN '2014'
                         WHEN @ProductVersion LIKE '13%'
                         THEN '2016'
                         WHEN @ProductVersion LIKE '14%'
                         THEN '2017'
                         ELSE 'Unknown'
                     END AS [SQL Server Version],
       SERVERPROPERTY('ProductVersion') AS [SQL Server Build],
       SERVERPROPERTY('edition') AS [SQL Edition],
       cpu_count,
       @@servername AS [ServerName],
       @Create_Date AS [DateInstalled],
       '[Your Name]' AS [Installer],
       '[CW Ticket #]' AS [CW Ticket],
       '[TOR #]' AS [TOR]
FROM sys.dm_os_sys_info;
