/* Restore Differentials
Restore the full backup in NORECOVEREY
then restore the database from the last Diff
Then restore through any logs after that diff
THEN restore the database with recovery
*/

RESTORE DATABASE DatabaseName
FROM DISK = 'PathToFull'
WITH 
STATS = 10
, NORECOVERY

RESTORE DATABASE DatabaseName
FROM DISK = 'PathToDiff'
WITH 
STATS = 10
, NORECOVERY

-- Optional: restore logs

RESTORE LOG DatabaseName
FROM DISK = 'PathToLog1'
WITH 
STATS = 10
, NORECOVERY

RESTORE DATABASE DatabaseName
WITH RECOVERY