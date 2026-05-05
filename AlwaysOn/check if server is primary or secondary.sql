declare @ag_name sysname = '' --put ag name here

select role_desc
from sys.dm_hadr_availability_replica_states s
    join sys.availability_groups g on g.group_id = s.group_id
where is_local = 1
and g.name = @ag_name

--alternative

declare @database_name sysname = '' --put database name here

select role_desc
from sys.dm_hadr_availability_replica_states s
    join sys.availability_databases_cluster d on d.group_id = s.group_id
    join sys.availability_replicas r on r.replica_id = s.replica_id
where r.replica_server_name = (
        select serverproperty('servername')
    )
    and d.database_name = @database_name