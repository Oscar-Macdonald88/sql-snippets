USE EIT_DBA;
GO

DECLARE @Customer NVARCHAR(255);
DECLARE @Server NVARCHAR(255);
SET @Customer = (SELECT TOP 1 value FROM EIT_monitoring_config WHERE configuration = 'customer_code')+ ' - Test';
SET @Server = 'Test from ' + CAST((SELECT SERVERPROPERTY('SERVERNAME')) AS NVARCHAR(255));

EXEC EIT_DBA..usp_eit_alert 
'n' -- 'y' if you want to page, otherwise 'n'
, @Customer
, 'Test'
, @Server
, '';