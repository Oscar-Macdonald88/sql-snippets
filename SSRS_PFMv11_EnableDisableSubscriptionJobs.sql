Declare @Replica Varchar(50)

Set @Replica = (select rs.role_desc from sys.[dm_hadr_availability_replica_states] rs
inner join [sys].[dm_hadr_availability_replica_cluster_states] rcs
on rs.replica_id = rcs.replica_id
where rcs.replica_server_name = SERVERPROPERTY('ServerName') and rs.group_id = '5D3DEED4-8E01-4BD7-A26A-9B75F4D1BE4E' AND is_local = 1)

Declare @sql varchar (300)

Declare cur_PFM_Job_ID cursor LOCAL for SELECT j.[job_id]
FROM [msdb].[dbo].[sysjobs] j
JOIN [msdb].[dbo].[syscategories] c
on j.category_id = c.category_id
Where c.name = '[Uncategorized (Local)]'
Declare @JobId UniqueIdentifier
open cur_PFM_Job_ID 
fetch next from cur_PFM_Job_ID  into @JobID 
While @@FETCH_STATUS = 0   
begin     
	If @Replica = 'SECONDARY' 
		Exec msdb.dbo.sp_update_job @job_id = @JobID, @enabled = 0
	Else If @Replica = 'PRIMARY'
		Exec msdb.dbo.sp_update_job @job_id = @JobID, @enabled = 1
	fetch next from cur_PFM_Job_ID     
	into @JobID   
end
close cur_PFM_Job_ID
deallocate cur_PFM_Job_ID