/*Data Files vs Log Files

Data Files
Equal fill algorithm: keeps data even within a filegroup
Each file will be filled at an even rate (striped, like RAID). There should be as little difference in the size of the used space between filegroup files as possible and they should grow as evenly as possible.
The PRIMARY filegroup is always available, but best practice is to use it for system files only.

Log Files
Unlike Data files, Log files don't have an equal fill, they can't (and don't need to) use filegroups.
Fills up log file 1, then moves to the next log file. Act as overflow files, because the files are completely chronological. Completely serial, like the VHS tape.
*/
-- Creating Filegroups

USE [master]
CREATE DATABASE [DB1]
ON PRIMARY -- on the Primary filegroup (the default filegroup)
(
    NAME = [DB1Data1],
    FILENAME = 'C:\SQLData\DB1Data1.mdf',
    SIZE = 10MB
),
FILEGROUP fgCurrent -- To create new filegroups, add the FILEGROUP <fgName> keyword to start a new list of files as a filegroup.
(
    NAME = [DB1Data2],
    FILENAME = 'C:\SQLData\DB1Data2.ndf',
    SIZE = 10MB
),
(
    NAME = [DB1Data3],
    FILENAME = 'C:\SQLData\DB1Data3.ndf',
    SIZE = 10MB
),
FILEGROUP fgArchive -- to start a new list of filegroups, add the FILEGROUP <fgName> keyword again.
(
    NAME = [DB1DataArchive],
    FILENAME = 'C:\SQLData\DB1DataArchive.ndf',
    SIZE = 10MB
)
LOG ON -- The log file can't be in a filegroup, so you declare it with LOG ON
(
    NAME = [DB1Log1],
    FILENAME = 'C:\SQLLogs\DB1Log1.ldf', -- log data file
    SIZE = 10MB
)

-- To add a new filegroup
ALTER DATABASE [DB1]
ADD FILEGROUP [NewFG]
GO
-- To add a file to an existing database to the new filegroup:
ALTER DATABASE [DB1]
ADD FILE
(
    NAME = N'newFile',
    FILENAME = N'C:\SQLData\fileName.ndf',
    SIZE = 4096KB,
    FILEGROWTH = 1024000KB
)
TO FILEGROUP [NewFG]

-- to create a table in the filegroup
USE [DB1]
CREATE TABLE T2
(col1 int)
on [fgCurrent]

USE [DB1]
CREATE TABLE T3
(col1 int)
on [NewFG]

-- you can see these files on Object Explorer Details (F7) under Tables
-- or you can use this to see all filegroups:
SELECT *  FROM sys.filegroups

-- use this to see all data files
SELECT * FROM sys.database_files

-- use this to see all files:
SELECT * FROM sys.data_spaces

-- to query which file exists to which filegroup, run this query:
SELECT df.file_id, df.name, ds.name AS Filegroup
FROM sys.database_files AS df
INNER JOIN sus.data_spaces AS ds
ON df.data_space_id = ds.data_space_id