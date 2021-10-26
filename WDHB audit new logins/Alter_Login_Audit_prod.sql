USE [master]
GO

/****** Object:  Audit [SSL-Audit-New-Principals]    Script Date: 19/09/2018 16:43:17 ******/
DECLARE @myid uniqueidentifier 
SET @myid = NEWID()
DECLARE @myidvarchar varchar(255)
Set @myidvarchar = CONVERT(varchar(255), @myid)
DECLARE @sqlcommand nvarchar(max);
SELECT @sqlcommand = '
CREATE SERVER AUDIT [SSL-Audit-New-Principals]
TO FILE 
(	FILEPATH = N''\\WAI-SQL-P-027\Audits''
	,MAXSIZE = 0 MB
	,MAX_ROLLOVER_FILES = 2147483647
	,RESERVE_DISK_SPACE = OFF
)
WITH
(	QUEUE_DELAY = 1000
	,ON_FAILURE = CONTINUE
	,AUDIT_GUID = " + @myidvarchar + "
)'
EXEC sp_executesql @sqlcommand;
ALTER SERVER AUDIT [SSL-Audit-New-Principals] WITH (STATE = ON)
GO
USE [master]
GO

CREATE SERVER AUDIT SPECIFICATION [SSL-Audit-New-Principals-Specification]
FOR SERVER AUDIT [SSL-Audit-New-Principals]
ADD (SERVER_PRINCIPAL_CHANGE_GROUP)
WITH (STATE = ON)
GO