SELECT s.step_id as 'Step ID',
    j.[name] as 'SQL Agent Job Name',
    s.database_name as 'DB Name',
    s.command as 'Command'
FROM msdb.dbo.sysjobsteps AS s
    INNER JOIN msdb.dbo.sysjobs AS j ON  s.job_id = j.job_id
WHERE  s.command LIKE '%mystring%'