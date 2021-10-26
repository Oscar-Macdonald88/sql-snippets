/* Restoring Logs
Consider your Transaction Logs like a VHS: To get to the middle you have to fast-forward to the middle, you can't select the middle from a menu.
The Transaction Log is just like that, you have to play the whole thing chronologically in order to reach a certain spot. To get from 2am to 5pm, you have to get through 3am, 4am 5am etc

Concept vs Fact
IF you have an entire TV season recorded across 3 VHSs, how can you tell when one episode starts and ends?
If you have 3 log backups, how can you tell when transactions start and end? They could span multiple logs.
ACID
- Atomicity
- Concistency
- Isolation
- Durability
*/

RESTORE DATABASE DatabaseName
FROM DISK = 'PathToFile'
WITH 
STATS = 10
, NORECOVERY  
-- NORECOVERY says 'Hold on to unfinished transactions (don't do the undo portion), because they may be completed in a future restore.
-- https://technet.microsoft.com/en-us/library/ms191455(v=sql.105).aspx#Relationship%20of%20RECOVERY%20and%20NORECOVERY%20Options%20to%20Restore%20Phases
-- This is the key to restoring the logs. Two portions to the recovery: undo and redo.
-- WITH RECOVERY: includes both redo and undo.
-- WITH NORECOVERY: omits undo phase to preserve uncommitted transactions
-- This puts the database into Restoring state so you can restore the log files:

RESTORE LOG DatabaseName
FROM DISK = 'PathToLog1'
WITH 
STATS = 10
, NORECOVERY

RESTORE LOG DatabaseName
FROM DISK = 'PathToLog2'
WITH 
STATS = 10
, NORECOVERY

-- Here is where you can restore the database, with or without restoring the last log

RESTORE LOG DatabaseName
FROM DISK = 'PathToLog3'
WITH 
STATS = 10
, NORECOVERY

RESTORE DATABASE DatabaseName
WITH RECOVERY -- this will start the undo process

-- an alternative to norecovery is the standby option. Allows you to have read-only access to the database while in Recovery mode
RESTORE DATABASE DatabaseName
FROM DISK = 'PathToFile'
WITH 
STATS = 10
, STANDBY = 'PathToFile.txt' 