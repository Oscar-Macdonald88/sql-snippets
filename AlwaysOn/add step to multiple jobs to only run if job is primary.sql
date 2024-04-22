-- Not working. Easier to write a Powershell script that can do this instead.
declare @availability_group_name nvarchar(128) = '' --Put availability group name here
drop table if exists #availability_group_jobs
CREATE TABLE #availability_group_jobs (
    job_name nvarchar(128) 
);
insert into #availability_group_jobs VALUES
('test1'),
('test2') --Put job names here

select 'USE [msdb]'
union all
select 'GO'
union all
select 'EXEC msdb.dbo.sp_add_jobstep @job_name = N'''+job_name+''' , @step_name=N''Check availability group role'', '
from #availability_group_jobs
union all
select '@step_id=1,'
union all
select '@cmdexec_success_code=0,'
union all
select '@on_success_action=3,'
union all
select '@on_fail_action=1,'
union all
select '@retry_attempts=0,'
union all
select '@retry_interval=0,'
union all
select '@os_run_priority=0, @subsystem=N''TSQL'','
union all
select '@command=N''if (select role_desc'
union all
select 'from sys.dm_hadr_availability_replica_states s'
union all
select 'join sys.availability_groups g on g.group_id = s.group_id'
union all
select 'where g.name = ''''' + @availability_group_name + ''''') <> ''''PRIMARY'''''
union all
select 'BEGIN'
union all
select 'exec xp_executesql N''''select 1/0'''''
union all
select 'END'','
union all
select '@database_name=N''master'', '
union all
select '@flags=0'
union all
select 'GO'
