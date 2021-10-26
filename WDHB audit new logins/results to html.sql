if OBJECT_ID('tempdb..#tmpLoginAudit', 'U') is not null
	drop table #tmpLoginAudit;
go

create table #tmpLoginAudit (
	event_time varchar(100),
	server_instance_name sysname,
	server_principal_name sysname,
	object_name sysname
	);
go

-- copy this section for each audit file
insert into #tmpLoginAudit
select convert(varchar, format(event_time, 'yyyy/MM/dd hh:mm tt')),
	server_instance_name,
	server_principal_name,
	object_name
from sys.fn_get_audit_file('\\WAI-SQL-T-025\Audits\SSL-Audit-New-Principals_A60A6514-457E-4E92-BE33-1EBFBECE849F*.sqlaudit', default, default) -- change this to match the correct path to the audit file!
where action_id = 'CR' -- CREATE events
	and event_time > DATEADD(month, - 1, GETDATE());-- get all events up to 1 month ago.
go


if ((select count(*) from #tmpLoginAudit) > 0)
	declare @today datetime;

	set @today = getdate();

	declare @tableName nvarchar(100) = 'Monthly ''New Login'' Audit: ' + convert(varchar, format(@today, 'dd-MM-yy'));
	declare @tableHTML nvarchar(MAX);

	set @tableHTML = N'<H1>' + @tableName + ' </H1>' 
	+ N'<table border="1">' 
	+ N'<tr><th>Day / Time</th><th>Instance</th>' 
	+ N'<th>Executed by</th><th>New Login</th>' 
	+ cast((
				select td = event_time,
					'',
					td = server_instance_name,
					'',
					td = server_principal_name,
					'',
					td = object_name
				from #tmpLoginAudit
				for xml PATH('tr'),
					TYPE
				) as nvarchar(max)) + N'</table>';

	print @tableHTML;
		EXEC msdb..sp_send_dbmail
		@profile_name = 'ManagedSQL',
		@recipients = 'oscar.macdonald@sqlservices.com',
		@subject = 'Monthly ''New Login'' Audit',
		@body = @tableHTML,
		@body_format = 'HTML';
go
