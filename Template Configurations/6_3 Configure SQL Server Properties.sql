use master;
go
exec sp_configure 'show advanced options', 1;
go
reconfigure
go
exec sp_configure 'backup compression default', 1;
go
reconfigure
go
exec sp_configure 'database mail xps', 1;
go
reconfigure
go
exec sp_configure 'remote admin connections', 1;
go
reconfigure
go
exec sp_configure 'xp_cmdshell', 1;
go
reconfigure
go
exec sp_configure
go