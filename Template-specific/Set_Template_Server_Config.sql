sp_configure 'show advanced options' ,1;
go

reconfigure with override;
go

sp_configure 'Database Mail XPs' ,1;
go

sp_configure 'remote admin connections' ,1;
go

sp_configure 'xp_cmdshell' ,1;
go

reconfigure with override;
go

sp_configure
