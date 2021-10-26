-- sample restore database for log shipping

RESTORE HEADERONLY 
FROM DISK = 'c:\FullPath.bak'

RESTORE FILELISTONLY 
FROM DISK = 'c:\FullPath.bak'

RESTORE DATABASE DatabaseName
FROM DISK = 'c:\FullPath.bak'
WITH
MOVE 'LogicalName' TO 'FullPathAndNameToNewLocationOnSecondary'
, MOVE 'LogicalName_log' TO 'FullPathAndNameToNewLocationOnSecondary_log'
, STATS = 1
, NOREPLACE
-- the REPLACE option is used as a safety net to prevent overwriting an existing database.