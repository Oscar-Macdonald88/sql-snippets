-- Works for SQL Agent jobs.
-- Make sure the job step is set to run on a non-AG joined database like master or tempdb.
declare @db_name sysname = '' --put db name here

if (
       sys.fn_hadr_is_primary_replica(@db_name) = 1 -- if database is primary
       or sys.fn_hadr_is_primary_replica(@db_name) is NULL --in case database has been removed from the AG
   )
begin
    print 'This server is the primary replica for database ' + @db_name + '. Running step'
    exec (N'use ' + @db_name + '; EXEC Dynamic SQL here') --put code, stored proc etc to run on primary replica here
end
else
begin
    print 'This server is not the primary replica for database ' + @db_name + '. Skipping step.'
end

