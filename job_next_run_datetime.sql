
if (select (CASE 
    WHEN sj.next_run_date > 0 THEN DATEADD(N,(NEXT_RUN_TIME%10000)/100,DATEADD(HH,NEXT_RUN_TIME/10000,CONVERT(DATETIME,CONVERT(VARCHAR(8),NEXT_RUN_DATE),112)))  
    ELSE CONVERT(DATETIME,CONVERT(VARCHAR(8),'19000101'),112) END )
	from msdb.dbo.sysschedules s 
join msdb.dbo.sysjobschedules sj on s.schedule_id = sj.schedule_id
join msdb.dbo.sysjobs j on j.job_id = sj.job_id where j.name = 'DBA_Maintenance') >= getdate() + 7
begin
select CASE 
    WHEN sj.next_run_date > 0 THEN DATEADD(N,(NEXT_RUN_TIME%10000)/100,DATEADD(HH,NEXT_RUN_TIME/10000,CONVERT(DATETIME,CONVERT(VARCHAR(8),NEXT_RUN_DATE),112)))  
    ELSE CONVERT(DATETIME,CONVERT(VARCHAR(8),'19000101'),112) END, getdate() + 7
	from msdb.dbo.sysschedules s 
join msdb.dbo.sysjobschedules sj on s.schedule_id = sj.schedule_id
join msdb.dbo.sysjobs j on j.job_id = sj.job_id where j.name = 'DBA_Maintenance'
end