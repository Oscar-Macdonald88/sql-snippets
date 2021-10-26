--Restore Basics.
/*
Simple Full Restore
    Just as you can't make a Log or Diff backup without first making a Full first, you can't restore a Log or Diff without a Full first
*/

RESTORE DATABASE DatabaseName
FROM DISK = 'c:\FullPath.bak'
WITH STATS = 10
-- , REPLACE
-- the REPLACE option is used to overwrite the existing database. You omit this if the database doesn't exist, or if you want a safety net before overwriting an existing database.

/* Restore with Move
This is VERY handy, especially with test or dev databases
Allows you to create a database with a different name OR to move the database to a different location eg from D: to E:. 
*/

-- File list only
RESTORE FILELISTONLY
FROM DISK = 'PathToFile'

-- restore database
RESTORE DATABASE DatabaseName 
FROM DISK = 'PathToFile' -- this is usually a .bak file, will check logical stored backup location
WITH
MOVE 'LogicalName' TO 'FullPathAndNameToNewLocation'
, MOVE 'LogicalName_log' TO 'FullPathAndNameToNewLocation_log'
, STATS = 10
, REPLACE

-- Restore Under Different Name
RESTORE DATABASE DatabaseName2
FROM DISK = 'PathToFile' -- this is usually a .bak file, will check logical stored backup location
WITH
MOVE 'LogicalName2' TO 'FullPathAndNameToNewLocation2'
, MOVE 'LogicalName2_log' TO 'FullPathAndNameToNewLocation2_log'
, STATS = 10
, REPLACE
-- if using RECOVERY without REPLACE, will get error: The tail of the log for the database "DatabaseName2" has not been backed up

-- Same, but generated with SSMS
USE [master]
RESTORE DATABASE [DatabaseName2] 
FROM  DISK = N'FullPathToBackup' 
WITH  
FILE = 2,  
MOVE N'OldLogicalName' TO N'FullPathAndNameToNewLocation2',  
MOVE N'OldLogicalName_log' TO N'FullPathAndNameToNewLocation2_log', 
NOUNLOAD,  STATS = 5
GO

-- If the database doesn't exist:
RESTORE DATABASE DatabaseName2 -- You can just specify the new database name
FROM DISK = 'PathToFile'
WITH
STATS = 10
, REPLACE

/*
Restore and Recovery
backups must be restored in a logically correct and meaningful restore sequence (like playing VHS tapes in order)

Database (complete database restore): restore and recover whole database, database is offline for duration of restore and recovery
Data file (file restore): Restore fron data file / set of files. Filegroupd that contain the files will be offline during restore and recovery.
Data Page (page restore): restoring individual databases:
 - An unbroken chain of log backups must be available, up to the current log file, and they must all be applied to bring the page up to date with the current log file.
 */
