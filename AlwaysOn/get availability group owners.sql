USE [master]
GO
SELECT ag.[name] AS AG_name, ag.group_id, r.replica_id, suser_sname(r.owner_sid) as owner, p.[name] as owner_name 
FROM sys.availability_groups ag 
   JOIN sys.availability_replicas r ON ag.group_id = r.group_id
   JOIN sys.server_principals p ON r.owner_sid = p.[sid]
--WHERE p.[name] = 'DOMAIN\DBAUser1'
GO  