select SERVERPROPERTY('servername') as [Server Name], dbe.service_account as [DB Engine service account], agt.service_account as [Agent service account], auth_scheme
from sys.dm_server_services dbe
cross join  sys.dm_server_services agt
cross join sys.dm_exec_connections
where dbe.servicename like 'SQL Server (%'
and agt.servicename like 'SQL Server Agent%'
and session_id = @@spid