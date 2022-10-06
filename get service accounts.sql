select SERVERPROPERTY('servername') as [Server Name], dbe.service_account as [DB Engine service account], agt.service_account as [Agent service account] 
from sys.dm_server_services dbe
cross join  sys.dm_server_services agt
where dbe.servicename like 'SQL Server (%'
and agt.servicename like 'SQL Server Agent%'