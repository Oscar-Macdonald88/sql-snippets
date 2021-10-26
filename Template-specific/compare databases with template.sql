--Check that all databases on the server are in the template
select name, state_desc, recovery_model_desc, is_read_only from sys.databases
where name NOT IN (select DatabaseName from SSLDBA..tbl_Databases)

--Check if there are any databases in template that are not on the server
select DatabaseName from SSLDBA..tbl_Databases
where DatabaseName NOT IN (select name from sys.databases)
