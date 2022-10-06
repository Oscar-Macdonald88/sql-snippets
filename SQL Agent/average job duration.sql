SELECT 
  job_name = name, 
  avg_sec  = rd,
  avg_mmss = CONVERT(VARCHAR(11),rd / 60) + ':' + RIGHT('0' + CONVERT(VARCHAR(11),rd % 60), 2)
FROM
(
  SELECT
    j.name, 
    rd = AVG(DATEDIFF(SECOND, 0, STUFF(STUFF(RIGHT('000000' 
       + CONVERT(VARCHAR(6),run_duration),6),5,0,':'),3,0,':')))
  FROM msdb.dbo.sysjobhistory AS h
  INNER JOIN msdb.dbo.sysjobs AS j
  ON h.job_id = j.job_id
  WHERE h.step_id = 0
  GROUP BY j.name
) AS t
ORDER BY job_name;