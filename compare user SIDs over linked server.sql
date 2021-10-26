
SELECT sp.[name], sp.[sid] as [Origin Server SID], l.[sid] as [Linked Server SID], 
sp.is_disabled, sp.default_database_name, sp.default_language_name
FROM .master.sys.server_principals AS sp -- put linked server here
LEFT JOIN master.sys.sql_logins AS l ON sp.[name]=l.[name]
where sp.[name] = l.[name] and sp.[sid] <> l.[sid]
AND sp.[type] IN ('U', 'G', 'S') 
AND
      UPPER(sp.[name]) NOT LIKE 'NT SERVICE\%' 
	  and UPPER(sp.[name]) NOT LIKE'##MS_%' 
	  AND
	  sp.[name] NOT IN ('NT AUTHORITY\SYSTEM')
