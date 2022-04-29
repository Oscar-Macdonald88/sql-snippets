if (select auth_scheme FROM sys.dm_exec_connections WHERE session_id = @@spid) = 'NTLM'
begin
select SERVERPROPERTY('servername'), '', 200, 'Server Info', 'An SPN hasn''t been successfully registered', NULL, 'Review whether an SPN has been registered for this server and consider adding one if there isn''t one already'
end