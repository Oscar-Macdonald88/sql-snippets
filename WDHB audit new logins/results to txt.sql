declare @fileName nvarchar(100) =  'Login Audit ' + format(getdate(), 'dd-MM-yy') + '.txt';

EXEC msdb..sp_send_dbmail
@profile_name = 'ManagedSQL',
@recipients = 'oscar.macdonald@sqlservices.com',
@subject = 'Monthly Created Login Audit',
@query = N'select format(event_time, ''yyyy/MM/dd hh:mm tt'') as [Time]
, server_instance_name as [Instance]
, server_principal_name as [Executed by]
, object_name as [New Login]
from sys.fn_get_audit_file (''D:\SQLDataDumps\SSL-Audit-New-Principals_A60A6514-457E-4E92-BE33-1EBFBECE849F_0_131818057243410000.sqlaudit'',default,default)
where action_id = ''CR''
and event_time > DATEADD(month, -1, GETDATE()) -- get all events up to 1 month ago.',
@query_result_header = 1,
@attach_query_result_as_file = 1,
@query_attachment_filename = @fileName;