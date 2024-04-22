SELECT sj.name AS [Name],
   --sh.step_name AS [StepName],
   CASE
       WHEN avg(sh.run_duration) > 235959
           THEN CAST((CAST(LEFT(CAST(avg(sh.run_duration) AS VARCHAR), LEN(CAST(avg(sh.run_duration) AS VARCHAR)) - 4) AS INT) / 24) AS VARCHAR) + '.' + RIGHT('00' + CAST(CAST(LEFT(CAST(avg(sh.run_duration) AS VARCHAR), LEN(CAST(avg(sh.run_duration) AS VARCHAR)) - 4) AS INT) % 24 AS VARCHAR), 2) + ':' + STUFF(CAST(RIGHT(CAST(avg(sh.run_duration) AS VARCHAR), 4) AS VARCHAR(6)), 3, 0, ':')
       ELSE STUFF(STUFF(RIGHT(REPLICATE('0', 6) + CAST(avg(sh.run_duration) AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
       END AS [AvgRunDuration (d.HH:MM:SS)],
   CASE
       WHEN max(sh.run_duration) > 235959
           THEN CAST((CAST(LEFT(CAST(max(sh.run_duration) AS VARCHAR), LEN(CAST(max(sh.run_duration) AS VARCHAR)) - 4) AS INT) / 24) AS VARCHAR) + '.' + RIGHT('00' + CAST(CAST(LEFT(CAST(max(sh.run_duration) AS VARCHAR), LEN(CAST(max(sh.run_duration) AS VARCHAR)) - 4) AS INT) % 24 AS VARCHAR), 2) + ':' + STUFF(CAST(RIGHT(CAST(max(sh.run_duration) AS VARCHAR), 4) AS VARCHAR(6)), 3, 0, ':')
       ELSE STUFF(STUFF(RIGHT(REPLICATE('0', 6) + CAST(max(sh.run_duration) AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
       END AS [MaxRunDuration (d.HH:MM:SS)]
FROM msdb.dbo.sysjobs sj
INNER JOIN [EIT_DBA].[dbo].[EIT_trend_jobhistory] sh
   ON sj.job_id = sh.job_id
   --where name in () -- insert jobs here
   group by [Name]
GO