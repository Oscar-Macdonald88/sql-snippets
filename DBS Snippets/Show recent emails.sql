--Select the last 12 hours of emails
	SELECT CONVERT(VARCHAR(32), send_request_date) AS [send_request_date], recipients, subject, body
	FROM msdb.dbo.sysmail_mailitems
		WHERE send_request_date>=DATEADD(HOUR, -12, GETDATE()) --VARIABLE: If you want a custom timeframe, change "-12" to whatever you want. Also, you can use SECOND, MINUTE, HOUR, DAY.
		AND subject LIKE '%%'
		AND body LIKE '%%'
		AND recipients LIKE '%%'