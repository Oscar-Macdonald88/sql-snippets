USE DatabaseName -- Change the name of the database 

DECLARE @USERNAME VARCHAR(MAX) = 'test' -- change the username to WMP\username if using a Windows login, or to the username if using SQL Server Login

SELECT 'GRANT VIEW DEFINITION ON [' + sch.name + '].[' + so.name + '] TO [' + @USERNAME + '];' [T-SQL] into #storedprocs
  FROM sys.sysobjects so join sys.schemas sch on so.uid = sch.schema_id
 WHERE (so.type = 'P')

select * from #storedprocs

-- get the first sql
declare @sql nvarchar(max) = (SELECT TOP 1 [T-SQL] FROM #storedprocs)
WHILE @sql is not null
BEGIN  

  -- Get next sql
  set @sql  = (SELECT TOP 1 [T-SQL] FROM #storedprocs)
  delete FROM #storedprocs where [T-SQL] = @sql
  EXEC (@sql)

END

drop table #storedprocs

