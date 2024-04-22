USE EIT_DBA;
GO

DECLARE @Customer NVARCHAR(255);
DECLARE @Server NVARCHAR(255);
DECLARE @Subject NVARCHAR(255);
DECLARE @Body NVARCHAR(255);
SET @Customer = (SELECT TOP 1 value FROM EIT_monitoring_config WHERE configuration = 'customer_code');
SET @Server = CAST((SELECT SERVERPROPERTY('SERVERNAME')) AS NVARCHAR(255));
SET @Subject = @Customer + ' - Test(Alert) - ' + @Server;
SET @Body = 'Test from ' + @Server

EXEC EIT_DBA..usp_eit_alert 
@custom_page = 'n' -- 'y' if you want to page, otherwise 'n'
, @custom_subj = @Subject
, @custom_page_subj = @Subject
, @custom_body = @Body
, @category = 'Alert'