-- useful for SQL Agent jobs that need to react dynamically for Log Shipping, possibly AlwaysOn too if needed
USE master
declare @database_name nvarchar(255) = '' -- add the target database name here
if (select top 1
        state_desc
    from master.sys.databases
    where name = @database_name) = 'ONLINE' and (select top 1
        is_read_only
    from master.sys.databases
    where name = @database_name) = 0
begin
    -- database is online and readable
    -- add the code you want to run on @database_name after the semicolon (;)
	exec ('USE ' +@database_name + '; select db_name()')
end
else
begin
    -- optional code if @database_name is not online/readable
end