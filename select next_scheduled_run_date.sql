	select next_scheduled_run_date
	from msdb.dbo.sysjobactivity ja
    join msdb.dbo.sysjobs j on j.job_id = ja.job_id
where j.name = 'DBA_Maintenance'