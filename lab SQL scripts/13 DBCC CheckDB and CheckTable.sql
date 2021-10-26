--Database console commands (DBCCs)
/*
CheckDB
Checks your database for consistency errors (a consistency error can mean a lot of things). Most common error is hardware error (bad disk, bad memory).
Note: If you perform a backup with corrupted data, the backup will include the corrupted data.
Running CHECKDB should be run as often as possible without interrupting use.
Getting into CHECKDB errors is very in-depth, out of scope for this topic.
*/

DBCC CHECKDB -- checkdb using current database context
-- or
DBCC CHECKDB(DatabaseName) -- check parameter DB
 
 /*
Index page errors are usually an easy fix
Worst case scenarios result in loss of corructed data
Minimum repair level can be seen at bottom of query that resulted in errors.
 */
 -- If there is a minimum repair level suggestion at the end of the query, you can fix the DB by rerunning the command but this time with the repair level added.
 -- Eg if the minimum repair level is repair_allow_data_loss:
ALTER DATABASE DatabaseName
SET single_user
DBCC CHECKDB(DatabaseName, repair_allow_data_loss)
GO
ALTER DATABASE DatabaseName
SET multi_user
GO