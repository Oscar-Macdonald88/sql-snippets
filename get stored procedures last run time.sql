--https://stackoverflow.com/questions/595742/last-run-date-on-a-stored-procedure-in-sql-server
-- sql version >= 2008
USE dbname -- UPDATE THIS
GO
SELECT o.name, 
       ps.last_execution_time 
FROM   sys.dm_exec_procedure_stats ps 
INNER JOIN 
       sys.objects o 
       ON ps.object_id = o.object_id
--WHERE o.name = ''
ORDER  BY 
       ps.last_execution_time DESC  

-- If you find a procedure here, you can be sure that it is accurate. 
-- If a certain procedure isn't listed, check current running queries to see if it's currently running