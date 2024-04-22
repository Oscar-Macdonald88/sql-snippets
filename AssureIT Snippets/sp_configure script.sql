Exec sp_configure 'show advanced options', 1;
Go
Reconfigure;
Go
EXEC sp_configure 'max server memory (MB)', 14000; --set memory as required.
GO
Reconfigure;
GO
EXEC sp_configure 'max server memory (MB)' -- check if memory is set as required.
GO
EXEC sp_configure 'min server memory (MB)', 5120; --set memory as required. Make sure this is not set to 0, minimum should be at least 1024
GO
Reconfigure;
GO
EXEC sp_configure 'min server memory (MB)' --check if memory is set as required.
Go
EXEC sp_configure 'optimize for ad hoc workloads', 1; --set to 1.
GO
Reconfigure;
GO
EXEC sp_configure 'optimize for ad hoc workloads' --check the setting.
go
EXEC sp_configure 'backup compression default', 1; --set to 1.
GO
Reconfigure;
GO
EXEC sp_configure 'backup compression default' --check the setting.
GO
EXEC sp_configure 'backup checksum default', 1; --set to 1.
GO
Reconfigure;
GO
EXEC sp_configure 'backup checksum default' --check the setting.
GO
EXEC sp_configure 'Agent XPs', 1; --set to 1.
GO
Reconfigure;
GO
EXEC sp_configure 'Agent XPs' --check the setting.
GO
EXEC sp_configure 'remote admin connections', 1; --set to 1.
GO
Reconfigure;
GO
EXEC sp_configure 'remote admin connections' --check the setting.
Go
EXEC sp_configure 'Database Mail XPs', 1; --set to 1.
GO
Reconfigure;
GO
EXEC sp_configure 'Database Mail XPs' --check the setting.
GO
EXEC sp_configure 'max degree of parallelism', 1; --set to 1.
GO
Reconfigure;
GO
EXEC sp_configure 'max degree of parallelism' –-check the setting.
GO