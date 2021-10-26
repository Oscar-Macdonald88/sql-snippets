-- Moving User Database Files
-- Useful to split the data/log files to different LUNs or separate data files to different LUNs or to archive data to different LUNs. 
ALTER DATABASE DBName
MODIFY FILE
(
    NAME = DBName,
    FILENAME = 'D:\SQLData\DBName.ndf'
)
-- The new path will be used the next time the database is started.

-- To get a list of all the databases on the server
SELECT * FROM sys.master_files
-- you will see the altered database will have its new FILENAME (physical_name) in the table

-- to make it official, there are 3 ways.
-- Bad way: backup and restore
-- Ok way: detatch and attach
-- Best practice: take database offline (to unlock it), then cut and paste the file to its new location
USE master
ALTER DATABASE DBName
SET OFFLINE
-- cut and paste the file to its new location in File Explorer
USE master
ALTER DATABASE DBName
SET ONLINE

-- if you are moving lots of files, you have to modify them one at a time, then put the database offline and move the files before putting it back online.
-- Don't move too many at once, or use an untested automation script, MAY RESULT IN CONFUSION OR DATA LOSS.
-- If you do make a mistake, the database will enter Suspect Mode (in Object Explorer it will be greyed out and have (Suspect) written next to it)
-- This just means one of the databse files couldn't come online, probably because you made a mistake with one of the files.
-- To fix this, alter the database again, correct the filepath, then try to bring online again.