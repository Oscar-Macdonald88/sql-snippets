IF (OBJECT_ID('tempdb..#sp_sql_top')) IS NOT NULL DROP PROC #sp_sql_top
GO
CREATE PROC #sp_sql_top  
 @reset  bit = 0
AS
 SET NOCOUNT ON
 IF (@reset = 1) BEGIN
    IF (OBJECT_ID('tempdb..##sysproc')) IS NOT NULL 
  DROP TABLE ##sysproc
 END
 IF (OBJECT_ID('tempdb..##sysproc')) IS NULL  BEGIN
  SELECT spid,waittime,cpu,physical_io,[memusage],last_batch 
  INTO ##sysproc 
  FROM master..sysprocesses
 END
 -- Remove any recycled spids:
 DELETE ##sysproc FROM ##sysproc t
 INNER JOIN master..sysprocesses s ON t.spid = s.spid
 WHERE t.last_batch < s.login_time
 
 SELECT 
  r.spid,
  r.blocked,
  r.waittime - ISNULL(t.waittime,0) waittime,
  r.lastwaittype,
  r.cpu - ISNULL(t.cpu,0) cpu,
  r.physical_io - ISNULL(t.physical_io,0) phyiscal_io,
  r.[memusage] - ISNULL(t.[memusage],0) [memusage],
  r.cmd,
  r.open_tran,
  CASE 
  WHEN r.last_batch > ISNULL(t.last_batch, GETDATE() -1) 
     THEN r.last_batch ELSE NULL END last_batch,
  CAST(RTRIM(r.hostname) AS varchar(30)) hostname,
  CAST(RTRIM(r.program_name) as varchar(128)) program_name,
  r.nt_username,
  r.loginame
 FROM
  master..sysprocesses r 
  RIGHT OUTER JOIN ##sysproc t ON r.spid = t.spid
 WHERE
  r.spid <> @@SPID
 ORDER BY
  r.cpu - t.cpu DESC
GO
EXEC #sp_sql_top -- or to reset: EXEC #sp_sql_top 1

--select * from sys.sysprocesses
--order by cpu desc