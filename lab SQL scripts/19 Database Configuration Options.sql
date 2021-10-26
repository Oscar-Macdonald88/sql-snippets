-- Database Configuration Options
-- Resource usage, user / login permissions, how transactions are logged.

-- AutoClose: Deallocates all objects from memory for a specified database
-- ie closes the database when the last user connection exists.
-- When you open a database, there are things that need to happen (memory allocation, disk spinning, etc). When it's closed, these things may need to be returned to the operating system. If there are a lot of connections and they all close and open rapidly it takes time for the resources to be reallocated every time. Best to keep it off to ensure performance.
-- To see which databases have AutoClose turned on:
SELECT name, is_auto_close_on FROM sys.databases

-- to turn off AutoClose:
USE master
ALTER DATABASE DBName
SET auto_close OFF

-- AutoShrink: Automatically shrinks DB and files at OS level every 30 minutes, but can cause severe fragmentation
-- Lecturers note:
--  AutoShrink is Bad, bad, bad, bad, bad.
--  There is no way around it, 
--  there is no case to convince him that AutoShrink is being used in a proper way,
--  there is no good time to use AutoShrink. Period.
--  Sounds good, doesn't work.
-- Severely fragments your database, if in conjunction with AutoGrow not only can it severly fragment the indexes in the entire database 
-- It can severely fragment the files at the file level as well.
SELECT name, is_auto_shrink_on FROM sys.databases

ALTER DATABASE DBName
SET auto_shrink OFF

-- Recovery Models
-- Simple, Bulk Logged, Full
-- Driven by business needs / model
-- System DBs must be in SIMPLE recovery, you can't change them to FULL

SELECT name, recovery_model_desc FROM sys.databases

ALTER DATABASE DBName
SET RECOVERY SIMPLE
-- choices: SIMPLE, BULK_LOGGED, FULL

-- Statistics Modes (Stats)
-- Used by SQL Server to decide which index to use when you perform a query:
-- It collects information about the data inside the table or inside the index itself
-- Some of this info is about the distribution/spread eg index 1-10, 12, 14-17, 20, 22 etc
-- Uses this to decide which index to use. As you update data, these indexes change and therefore the stats change.
-- Stats needs to be maintained to be effective. Can be maintained manually, semi-automatically or by SQL Server itself.
-- Change the frequency SQL Server updates the stats. Default is when 20% of the data has changed with (priority) base number of 500 rows changed.
-- Statistics Update Modes:
-- Synchronous: Default. Force queries to wait when stats are out of date. Can take a while with large tables. Optimal, but is time consuming when stat rebuild has been triggered
-- Asynchronous: Allows queries to continue with old stats while building new ones in the background. Not optimal, but less time consuming.
SELECT name, is_auto_update_stats_on, is_auto_update_stats_async_on FROM sys.databases
-- Microsoft recommends that for BIZTALK databases you turn auto_update_stats off

ALTER DATABASE DBName
SET auto_update_statistics_async ON

-- Restricting Access and Maintennance Modes
-- Single User: Allows only one user
-- Restricted User: Allows only db_owner role, sysadmin, or dbcreator
-- Multi User: Allows all users

SELECT name, user_access_desc FROM sys.databases
GO
ALTER DATABASE DBName
SET single_user
-- options: single_user, restricted_user, multi_user