select SERVERPROPERTY('servername') as [Server Name], dbe.service_account as [DB Engine service account], agt.service_account as [Agent service account], auth_scheme
from sys.dm_server_services dbe
cross join  sys.dm_server_services agt
cross join sys.dm_exec_connections
where dbe.servicename like 'SQL Server (%'
and agt.servicename like 'SQL Server Agent%'
and session_id = @@spid

-- for Reporting
if (select auth_scheme FROM sys.dm_exec_connections WHERE session_id = @@spid) = 'NTLM'
begin
select SERVERPROPERTY('servername'), '', 200, 'Server Info', 'An SPN hasn''t been successfully registered', NULL, 'Review whether an SPN has been registered for this server and consider adding one if there isn''t one already'
end