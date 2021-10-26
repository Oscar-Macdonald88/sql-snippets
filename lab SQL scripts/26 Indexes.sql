-- Indexes
-- Clustered and Non-clustered
-- Getting index info from Dynamic Management Views (DMVs)
-- Filtered indexes
-- Statistics (support certqain functions and optimizers)
-- Index Maintennance

-- SS accesses data using a table scan or an clustered index scan
--  table scan reads ALL the pages
--  when using an index, SS uses a clustered index scan search  (tree search).
-- Create indexes directly, or by specifying a PRIMARY KEY
-- Tables are either structured as a heap or clustered index
--  Note, Heap = Index ID 0     Clustered Index = Index ID 1

-- Clustered Indexes
--  Rows are stored in a logical order (the order you specified)
--  This defines the order of the table itself (nodes, leafs).
--  The clustered index is a property of the table itself, and in escence the row it belongs to as well
--  Because of this, you can only have one clustered index per table because it can't be ordered in multiple ways. 
--  A table without a clustered index is known as a heap
--  Operations:
--      INSERT:
--          Each new row must be placed into the correct logical position
--          May involve splitting pages of the table
--      UPDATE:
--          The updated row can either remain in the same place if it still fits and if the key is still the same
--          If it no longer fits, the page needs to be split
--          If the key has changed, the row needs to be moved to the correct position
--      DELETE:
--          Frees up space by flagging the data as unused (garbage collection?)
--      SELECT:
--          Queries related to the key can seek 
--          Queries related to the key can scan and void sorts

USE tempdb;
GO

-- Create a table without a primary key (a heap)
CREATE TABLE dbo.PhoneLog
(
    PhoneLogID int IDENTITY(1,1),
    LogRecorded datetime2 NOT NULL,
    PhoneNumberCalled nvarchar(100) NOT NULL,
    CallDurationMs int NOT NULL
);
GO;

-- Show execution plan for a scan (in SSMS)
SELECT * FROM dbo.PhoneLog
-- The execution plan will show that it performed a table scan for the heap

-- Drop the table
DROP TABLE dbo.PhoneLog

-- Recreate the table with a primary key
CREATE TABLE dbo.PhoneLog
(
    PhoneLogID int IDENTITY(1,1) PRIMARY KEY, -- this creates a clustered index
    LogRecorded datetime2 NOT NULL,
    PhoneNumberCalled nvarchar(100) NOT NULL,
    CallDurationMs int NOT NULL
);
GO;

-- Show execution plan for a scan (in SSMS)
SELECT * FROM dbo.PhoneLog
-- The execution plan will show that it performed a tree search

-- Query sys.indexes to view the structure
SELECT * FROM sys.indexes WHERE OBJECT_NAME(object_id) = N'PhoneLog';
GO
SELECT * FROM sys.key_constraints WHERE OBJECT_NAME(parent_object_id) = N'PhoneLog';
GO

-- No need to drop the table because it's in tempdb


-- Non-Clustered Indexes
-- Additional indexes can be created
-- These are called nonclustered indexes (Index ID 2+)
-- Separate object to the table (whereas a clustered index is the physical ordering of the table itself)
-- i.e it is a property of the row, not of the table
-- Leaf level contains a pointer to the table where the rest of the columns can be found

-- Covering Indexes and INCLUDE
-- A covering index is an index that can provide all the column data required to fullfil a query
--  Leaf nodes contain all columns in the SELECT clause, so there is no need to look up data pages in heap or clustered index
--  two nonclustered indexes together create a Covering Index (?)
-- Provides better performance as it removes the need to lookup the data in the table structure
-- Prior to SS 2005, toy had to create a composite index across multiple columns (expensive)
-- Now the INCLUDE clause is used to insert column data into the leaf node of a non-clustered index

USE tempdb;
GO

CREATE TABLE dbo.Book
(
    ISBN nvarchar(20) PRIMARY KEY,
    Title nvarchar(50) NOT NULL,
    ReleaseDate date NOT NULL,
    PublisherID int NOT NULL
);
GO

-- Create a nonclustered Covering Index on PublisherID and ReleaseDate in descending order
CREATE NONCLUSTERED INDEX IX_Book_Publisher
ON dbo.Book (PublisherID, ReleaseDate DESC);
GO
-- PublisherID and ReleaseDate are now at the leaf level of the nonclustered index

-- Request an estimated execution plan for a query that needs lookups (in SSMS)
SELECT PublisherID, Title, ReleaseDate
FROM dbo.Book
WHERE ReleaseDate > DATEADD(year, -1, SYSDATETIME()) -- where the release date is less than a year ago
ORDER BY PublisherID, ReleaseDate DESC;
GO
-- The estimated plan includes:
--  An Index Scan, with an output list: ISBN, ReleaseDate and PublisherID
--      The clustered index key exists in all nonclustered indexes
--      Querying for ISBN, ReleaseDate and PublisherID, that would be a covering index. 
--      But the title is not in the nonclustered index, so if queried it will not be part of the covering index. 
--      So a clustered key lookup is needed
--  A Key Lookup (Clustered)
--      Looks up the title using the non-clustered index(?)
--  A nested loop, to join matching values returned from the lookup and the scan.

-- You can create a new index on PublisherID and ReleaseDate and INCLUDE the Title
CREATE NONCLUSTERED INDEX IX_Book_Publisher -- same as before
ON dbo.Book (PublisherID, ReleaseDate DESC)
INCLUDE (Title) -- This time you add the Title within the nonclustered index
-- So when you get to the leaf level of the nonclustered index, the optimizer will also be given the Title
WITH DROP_EXISTING;
GO

-- Again, request an estimated execution plan for a query that needs lookups
SELECT PublisherID, Title, ReleaseDate
FROM dbo.Book
WHERE ReleaseDate > DATEADD(year, -1, SYSDATETIME()) -- where the release date is less than a year ago
ORDER BY PublisherID, ReleaseDate DESC;
GO
-- The estimated execution plan includes a single Index Scan which includes the ISBN, Title, ReleaseDate and PublisherID

-- You can query which columns are included in a database
USE AdventureWorks -- need to use a proper database, not tempdb
SELECT object_id, is_included_column FROM sys.index_columns;
GO
-- within the index columns, you can see whether it has been included or not.

-- You can also view this within Object Explorer
-- DB -> Tables -> TableName -> Indexes -> Double click NonclusteredIndexName -> Included Columns tab