/*
SQL Server Backups:
Creating a Backup Modes:
What is the Recovery Point Objective (RPO)?
    How much data can you afford to lose?
    0 = $$$
What is the Recovery Time Objective (RTO)?
    How long can you afford to be down?
    0 = $$$
*/
-- Full Backups
-- You can't take any other backup unless you create a Full Backup first. Everything else starts from a full backup.

BACKUP DATABASE DatabaseName
TO 
DISK = 'FullFileNamePath', -- the accepted file extension for the sql server backup file
-- file path example: 'c:\Program Files\Microsoft SQL Server\MSSQL14.SSL_DEVELOPER\MSSQL\DATA\FoodData1.mdf'
DISK = 'FullFileNamePath2' -- append extra DISKs to create multiple backups.
WITH INIT
, FORMAT
, STATS = 10
/*
These comma separated values start on new lines so that you can easily cut and paste new values
INIT = Initialize backup by overwriting any existing file. Without INIT the backups are concatenated in the same backup file.
FORMAT = along with INIT, reformats the existing file before writing the backup file (prevents header corruption) Eg if you added a new DISK path (as above) and FORMAT is not included then SQL will throw an error and exit abnormally from the backup process because the second DISK wasn't included in the original header.
STATS = indicate progress in percentage steps
*/

-- Log Backups
BACKUP LOG DatabaseName
TO
DISK = 'FullFileNamePath'
-- if you want to create different log backup files eg with timestamps just program one.

-- Differential Backups (Diffs)
-- A Diff backup is a backup of all activity since the last full backup
-- This IS cumulative (unlike the other backups)
-- It can shorten your recovery time. Goes at the extent level and only backs up the extents that have had changes. Restore full backup then restore latest diff.

BACKUP DATABASE DatabaseName
TO 
DISK = 'FullFileNamePath'
WITH INIT
, FORMAT
, STATS = 10
, DIFFERENTIAL

-- Filegroup backup
-- Kind of like a Diff, only backing up a specific filegroup, not entire DB. Good for large databases that can't be daily backed up timely. Can manage your backup situation if you need to infrequently backup some data like archives.

BACKUP DATABASE DatabaseName
filegroup = 'FG1'
,filegroup = 'FG2'
TO 
DISK = 'FullFileNamePath'
WITH INIT
, FORMAT
, STATS = 10

-- System Database Backups (master, model, msdb)
-- Note, you can't (and don't have to) back up tempdb
BACKUP DATABASE master -- or model / msdb
TO
DISK = 'FullFileNamePath'
WITH INIT
, FORMAT
-- master can only perform full backups.