-- Database File Management
-- Three types of Industry Standard Files and Extensions for databases:
--  MDF: Master data file
--  NDF: Non-master data file
--  LDF: Log data file

USE [master]
CREATE DATABASE [DB1]
ON PRIMARY -- this is important
(
    NAME = [DB1Data1],
    FILENAME = 'C:\SQLData\DB1Data1.mdf',  -- master data file
    SIZE = 10MB
),
(
    NAME = [DB1Data2],
    FILENAME = 'C:\SQLData\DB1Data2.ndf', -- non-master data file
    SIZE = 10MB
),
(
    NAME = [DB1Data3],
    FILENAME = 'C:\SQLData\DB1Data3.ndf',
    SIZE = 10MB
),
(
    NAME = [DB1Log1],
    FILENAME = 'C:\SQLLogs\DB1Log1.ldf', -- log data file
    SIZE = 10MB
)

-- If somebody has detatched a database and wants you to reattach it, you NEED to attach a file with the extension .mdf
CREATE DATABASE BadDBName
ON (FILENAME = 'C:\SQLData\BadDBName')
FOR ATTACH;
-- The FOR ATTACH option requires thaty at least the primary file be specified
-- If the master data file isn't specified, you'll have no idea which file it is.

DROP DATABASE DBNAME -- this will drop the database from sys.databases and will delete all the data / log files.

sp_detatch_db 'DBName', 'true'; -- this will drop the database from sys.databases but keep the data / log files.

select * from sys.databases -- use this to verify the database has been removed from sys.databases
