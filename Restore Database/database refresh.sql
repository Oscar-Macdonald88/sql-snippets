--1.	Double check the instance name and server name of the source server and the destination server.

--2.	Get internal restore files
RESTORE FILELISTONLY
FROM DISK = 'C:\MyDB\BasicSimpleDBBackup.bak'

RESTORE HEADERONLY
FROM DISK = 'E:\SQLDataDumps\To_Restore\magiqbudgeting_FULL_20180322.dat'


--3.	Check the data and log file size using 

use DB_name 
go
sp_helpfile 'Db_name'
go


--4.	Check the size of the disks where the data files, log files and backups are placed. 
--5.	Check if any existing connections are in place, if yes check by sp_who2 (after spids 50) which process is opened and what needs to be closed. Talk to the client and ask if the database is in use and if the existing connection is by SQL Services close all the connections. Remember, any of your open queries and property windows are SPIDs
--6.	Check for the orphaned users :

--First, make sure that this is the problem. This will lists the orphaned users:
EXEC sp_change_users_login 'Report'

--If you already have a login id and password for this user, fix it by doing:
EXEC sp_change_users_login 'Auto_Fix', 'user'

--If you want to create a new login id and password for this user, fix it by doing:
EXEC sp_change_users_login 'Auto_Fix', 'user', 'login', 'password'

--7.	Try restoring by restoring command:

--Basic restore
RESTORE DATABASE BasicFullDB
FROM DISK = 'C:\MyDB\BasicFullDBBackup.bak'
WITH stats = 1, replace


--Restore items to a different location
RESTORE DATABASE BasicSimpleDBRestored
FROM DISK = 'C:\MyDB\BasicSimpleDBBackup.bak'
WITH 
move 'BasicSimpleDB' to 'F:\TestMoveOnRestore\BasicSimpleDBRestored.ldf',
 stats = 1, replace


--Basic restore with log
RESTORE DATABASE BasicFullDBRestored
FROM DISK = 'C:\MyDB\BasicFullDBBackup.bak'
WITH stats = 1, NORECOVERY, replace

RESTORE DATABASE BasicFullDBRestored
FROM DISK = 'C:\MyDB\BasicFullDBBackupDif.dif'
WITH stats = 1, NORECOVERY, replace

RESTORE LOG BasicFullDBRestored
FROM DISK = 'C:\MyDB\BasicFullDBLog.trn'
WITH stats = 1, NORECOVERY

RESTORE DATABASE BasicFullDBRestored
WITH RECOVERY
