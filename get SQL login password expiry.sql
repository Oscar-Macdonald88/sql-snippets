SELECT @@SERVERNAME AS ServerName, SL.name AS LoginName
,LOGINPROPERTY(SL.name, 'PasswordLastSetTime') AS PasswordLastSetTime
,ISNULL(CONVERT(varchar(100),LOGINPROPERTY(SL.name, 'DaysUntilExpiration')),'Never Expire') AS DaysUntilExpiration
,ISNULL(CONVERT(varchar(100),DATEADD(dd, CONVERT(int, LOGINPROPERTY(SL.name, 'DaysUntilExpiration')),getdate() + 1),101),'Never Expire') AS PasswordExpirationDate,

CASE
WHEN is_expiration_checked = 1 THEN 'TRUE' ELSE 'FALSE'
END AS PasswordExpireChecked

FROM sys.sql_logins AS SL

WHERE SL.name NOT LIKE '##%' AND SL.name NOT LIKE 'endPointUser' and is_disabled = 0 and is_expiration_checked = 1

ORDER BY (LOGINPROPERTY(SL.name, 'PasswordLastSetTime')) DESC