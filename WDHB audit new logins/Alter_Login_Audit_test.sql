USE [master]
GO

/****** Object:  Audit [SSL-Audit-New-Principals]    Script Date: 19/09/2018 16:43:17 ******/
CREATE SERVER AUDIT [SSL-Audit-New-Principals]
TO FILE 
(	FILEPATH = N'\\WAI-SQL-T-025\Audits'  -- share this folder
	,MAXSIZE = 0 MB
	,MAX_ROLLOVER_FILES = 2147483647
	,RESERVE_DISK_SPACE = OFF
)
WITH
(	QUEUE_DELAY = 1000
	,ON_FAILURE = CONTINUE
	,AUDIT_GUID = 'a60a6514-457e-4e92-be33-1ebfbece849f' -- requires new GUID each time it is run.
)
ALTER SERVER AUDIT [SSL-Audit-New-Principals] WITH (STATE = ON)
GO
USE [master]
GO

CREATE SERVER AUDIT SPECIFICATION [SSL-Audit-New-Principals-Specification]
FOR SERVER AUDIT [SSL-Audit-New-Principals]
ADD (SERVER_PRINCIPAL_CHANGE_GROUP)
WITH (STATE = ON)
GO