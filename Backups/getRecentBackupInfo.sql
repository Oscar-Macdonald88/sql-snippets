SELECT B.database_name,B.server_name,B.[name],M.physical_device_name,
B.[type],bms.software_name, B.backup_start_date,B.backup_finish_date
from msdb..backupset B JOIN msdb..backupmediafamily M
ON B.media_set_id = M.media_set_id
inner join msdb.dbo.backupmediaset bms on b.media_set_id = bms.media_set_id
WHERE backup_start_date >= dateadd(dd,-1,getdate()) -- '2008-01-16'
AND B.[type] <> 'L'
--AND M.physical_device_name NOT LIKE 'T:\%'
ORDER BY database_name 