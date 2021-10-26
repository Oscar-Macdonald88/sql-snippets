declare @jobName varchar(250) = '' -- set job name here

SELECT sjh.instance_id, -- This is included just for ordering purposes
   job_name = sj.name,
   sjh.step_id,
   sjh.step_name,
   sjh.sql_message_id,
   sjh.sql_severity,
   sjh.message,
   sjh.run_status,
   -- adjusted values to convert to date
   convert(date, left(sjh.run_date, 4) + '-' +
               substring(convert(varchar(8), sjh.run_date), 5, 2) + '-' +
               right(sjh.run_date, 2)) run_date,
   -- adjusted values to convert to time
   convert(time, left(right('00000' + convert(varchar(6), sjh.run_time), 6), 2) + ':' +
               substring(right('00000' + convert(varchar(6), sjh.run_time), 6), 3, 2) + ':' +
               right(right('00000' + convert(varchar(6), sjh.run_time), 6), 2)) run_time,
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