declare @jobName varchar(250) = '' -- set job name here

SELECT sjh.instance_id, -- This is included just for ordering purposes
   job_name = sj.name,
   sjh.step_id,
   sjh.step_name,
   sjh.sql_message_id,
   sjh.sql_severity,
   sjh.message,
   sjh.run_status,
   msdb.dbo.agent_datetime(sjh.run_date, sjh.run_time) RunDateAndTime,
   sjh.run_duration,
   operator_emailed = so1.name,
   operator_netsent = so2.name,
   operator_paged = so3.name,
   sjh.retries_attempted,
   sjh.server
FROM msdb.dbo.sysjobhistory sjh
LEFT OUTER JOIN msdb.dbo.sysoperators so1  ON (sjh.operator_id_emailed = so1.id)
LEFT OUTER JOIN msdb.dbo.sysoperators so2  ON (sjh.operator_id_netsent = so2.id)
LEFT OUTER JOIN msdb.dbo.sysoperators so3  ON (sjh.operator_id_paged = so3.id),
msdb.dbo.sysjobs_view sj
WHERE (sj.job_id = sjh.job_id)
and sj.name = @jobName
ORDER BY sjh.instance_id