--Db corruption
--reference: for db repair: http://sqlmag.com/database-backup-and-recovery/using-database-repair-disaster-recovery
--& http://www.sqlskills.com/blogs/paul/finding-table-name-page-id
--also Sam Stedman http://SteveStedman.com


--1. run DBCC check across db to confirm consistency errors & identify the table. 
USE [dbname];
GO 
DBCC CheckDB([dbname]) WITH NO_INFOMSGS;


--2. check SS Error log & error msgs


--3. can run select query on corrupt table to expose the corruption
SELECT * from [db]..[tbl]


--3. double check that object id as defined in the DBCC CHECKDB output ..returns object name, 
SELECT * FROM sys.objects
 WHERE object_id = [objectid];

--returns same info as CHECKDB, just another check if reqd
DBCC CheckTable([tablename] WITH NO_INFOMSGS;


--4. whats in the page?  --returns the page header info, look at the Metadata: ObjectID field, refer http://www.sqlskills.com/blogs/paul/finding-table-name-page-id/
-- Also this link explains MetaData: IndexId values http://www.sqlservercentral.com/articles/Corruption/65804/
DBCC TRACEON(3604) with no_infomsgs;
DBCC Page([dbname], 1, [pageid], 2) WITH NO_INFOMSGS;
DBCC TRACEOFF(3604)

--5. repair the corruption using DBCC CHECKDB REPAIR_ALLOW_DATA_LOSS
-- go into single user mode, so that nobody else is in the way... run each statement separately, esp in prod environment, as this is easier to troubleshoot. 
ALTER DATABASE [dbname] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;    --closes all connections as otherwise query may hang ie be in SUSPENDED state
GO																	--eg ALTER DATABASE [dbname] SET SINGLE_USER hung, sp_who2 showed it was being blocked & Activity Monitor showed the query was in a SUSPENDED state with the cmd recorded as ALTER DB, 
																	--which indicates that it was unable to complete the first statement due to blocking by multiple spids. 
																	--sys_dm_exec_requests showed 0% complete and 0 time remaining, which indicated that it hadn�t progressed to the DBCC statement.
																	--good idea to monitor progress of query via sys.dm_exec_requests as this will pick up hung query more quickly. 
DBCC CHECKDB ([dbname], REPAIR_ALLOW_DATA_LOSS) WITH ALL_ERRORMSGS, NO_INFOMSGS;
GO


--6. run DBCCs again to confirm corruption has been repaired & no other corruption is present
ALTER DATABASE [dbname] SET MULTI_USER WITH ROLLBACK IMMEDIATE;
DBCC CheckDB([dbname]) WITH NO_INFOMSGS; 


