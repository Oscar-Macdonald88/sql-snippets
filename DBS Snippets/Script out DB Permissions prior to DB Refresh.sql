--PRE REFRESH DB Script
--Run this on your target DB before refreshing it. Save the scripts to a .txt file on the file system.
	DECLARE @login VARCHAR(255) 
 
	SET @login = '%%'
 
	SELECT '0.0' AS [Step], CONVERT(VARCHAR(8000), '-- Database: ['+DB_NAME())+'] on server ['+CONVERT(VARCHAR(250),SERVERPROPERTY('ServerName'))+']' as [TSQL]
 
	UNION ALL
	SELECT '0.1', 'USE ['+DB_NAME()+']'
	UNION ALL
	SELECT '0.2', 'GO'
	UNION ALL
	SELECT '0.3', '' WHERE @login = '%%'
	UNION ALL 
	SELECT '0.4', '--Remember to RESOLVE ORPHANED LOGINS!' WHERE @login = '%%'
	UNION ALL 
	SELECT '0.5', '--EXEC sp_change_users_login ''Report''' WHERE @login = '%%'
	UNION ALL 
	SELECT '0.6', '--EXEC sp_change_users_login ''Auto_Fix'', ''<user>''' WHERE @login = '%%'
 
	UNION ALL
	SELECT '1.0', ''
	UNION ALL
	SELECT '1.1', '-- Database Level Security: Part A'
	UNION ALL
 
	--Database Level Security
	SELECT 
		'1.5' AS [Step]
		, TSQL = 'CREATE USER '+QUOTENAME(u.name)+' FOR LOGIN '+QUOTENAME(u.name)
	FROM sys.database_permissions AS rm
	INNER JOIN
	sys.database_principals AS u
	ON rm.grantee_principal_id = u.principal_id
	WHERE rm.major_id = 0
	and u.name not like '##%' 
	and lower(u.name) LIKE lower(@login)
	and u.name not in ('dbo', 'sa', 'public')
	--ORDER BY rm.permission_name ASC, rm.state_desc ASC
 
	UNION ALL
	SELECT '2.0', ''
	UNION ALL
	SELECT '2.1', '-- Database Level Security: Part B'
	UNION ALL
 
	--Database Level Security
	SELECT 
		'2.5' AS [Step]
		, TSQL = rm.state_desc + N' ' + rm.permission_name + N' TO ' + cast(QUOTENAME(u.name COLLATE DATABASE_DEFAULT) as nvarchar(256)) 
	FROM sys.database_permissions AS rm
	INNER JOIN
	sys.database_principals AS u
	ON rm.grantee_principal_id = u.principal_id
	WHERE rm.major_id = 0
	and u.name not like '##%' 
	and lower(u.name) LIKE lower(@login)
	and u.name not in ('dbo', 'sa', 'public')
	--ORDER BY rm.permission_name ASC, rm.state_desc ASC
 
	UNION ALL
	SELECT '3.0', ''
	UNION ALL
	SELECT '3.1', '-- Database Level Roles'
	UNION ALL
 
	--Database Level Roles
	SELECT DISTINCT
		'3.5' AS [Step]
		,TSQL2 = 'EXEC sp_addrolemember @membername = N''' + d.name COLLATE DATABASE_DEFAULT + ''', @rolename = N''' + r.name + ''''
	FROM sys.database_role_members AS rm
	inner join sys.database_principals r on rm.role_principal_id = r.principal_id
	inner join sys.database_principals d on rm.member_principal_id = d.principal_id
	where d.name not in ('dbo', 'sa', 'public')
		and lower(d.name) LIKE lower(@login)
 
	UNION ALL
	SELECT '4.0', ''
	UNION ALL
	SELECT '4.1', '-- Database Level Explicit Permissions'
	UNION ALL
 
	--Database Level Explicit Permissions
	SELECT 
		'4.5' AS [Step]
		, TSQL = CASE WHEN (perm.state_desc='GRANT_WITH_GRANT_OPTION') THEN 'GRANT' ELSE perm.state_desc END + N' ' + perm.permission_name 
		+ N' ON ' + QUOTENAME(SCHEMA_NAME(obj.schema_id)) + '.' + QUOTENAME(obj.name) 
		+ N' TO ' + QUOTENAME(u.name COLLATE database_default)
		+ N' ' + CASE WHEN (perm.state_desc='GRANT_WITH_GRANT_OPTION') THEN 'WITH GRANT OPTION' ELSE '' END
	FROM sys.database_permissions AS perm
	INNER JOIN
	sys.objects AS obj
	ON perm.major_id = obj.[object_id]
	INNER JOIN
	sys.database_principals AS u
	ON perm.grantee_principal_id = u.principal_id
	LEFT JOIN
	sys.columns AS cl
	ON cl.column_id = perm.minor_id AND cl.[object_id] = perm.major_id
	where 
	obj.name not like 'dt%'
	and obj.is_ms_shipped = 0
	and u.name not in ('dbo', 'sa', 'public')
	and lower(u.name) LIKE lower(@login)
	ORDER BY [Step], [TSQL]