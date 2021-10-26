select format(event_time, 'yyyy/MM/dd hh:mm tt') as [Time]
, server_instance_name as [Instance]
, server_principal_name as [Executed by]
, object_name as [New Login]
from sys.fn_get_audit_file ('D:\SQLDataDumps\SSL-Audit-New-Principals_A60A6514-457E-4E92-BE33-1EBFBECE849F_0_131818057243410000.sqlaudit',default,default)
where action_id = 'CR' -- CREATE
    and event_time > DATEADD(month, -1, GETDATE()) -- get all events up to 1 month ago.
GO