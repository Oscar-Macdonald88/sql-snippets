-- Index Fragmentation
-- Fragmentation occurs when changing data causes index pages to split
--  Internal Fragmentation: pages are not full
--  External Fragmentation: pages are not in logical sequence

-- Detecting fragmentation
--  Look at index properties in SSMS (quite an expensive operation)
--  sys.dm_db_index_physical_stats as seen in 26-1


-- Removing Fragmentation

-- REBUILD
-- Takes the index offline and rebuilds it entirely. Needs free space to perform. Note: beware of log space requirements
-- This is performed as a single transaction. Rebuilding a large index can take a long time (10-12 hours) and if cancelled will rollback entire transaction.
ALTER INDEX NonclusteredIndexName
ON SchemaName.TableName
REBUILD;

-- REORGANIZE (sometimes referred to as DEFRAG(MENT))
-- Sorts the pages like REBUILD but is always online
-- Uses less Transaction Log space, not run as a single transaction.

-- Online Index Operations:
-- Enterprise Edition of SS can rebuild indexes online
-- Snables concurrent user access
-- Slower than the equivalent offline operation.
-- Bigger space requirements (effectively duplicates the database while creating a new index in parallel with the old index)
-- Lots of updates during the rebuild will use tempdb heavily until the rebuild completes
ALTER INDEX NonclusteredIndexName
ON SchemaName.TableName
REBUILD
WITH (ONLINE = ON, MAXDOP = 4);


