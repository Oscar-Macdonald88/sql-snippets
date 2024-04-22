declare @domain nvarchar(255) = 'hnz.co.nz:1433' -- set this to the correct domain

select 'setspn -A MSSQLSvc/'+dns_name+' .'+@domain+s.service_account from sys.availability_group_listeners
  join sys.dm_server_services s
  on 1=1
  where s.servicename like 'SQL Server (%'