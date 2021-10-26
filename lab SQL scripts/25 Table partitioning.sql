-- Table partitioning
-- Splitting tables across multiple filegroups to save on I/O and makes managing large tables more efficient
-- Basically scale-out at the table level
-- Put relevant data on tier 1 LUN and archived data on tier 4

-- Example of simplest partition table: every time you create a table, you're creating a partition table with a single partition table!
-- ie All tables are Partition Tables
CREATE TABLE T1
(
    col1 int
) 

-- To check partitions
SELECT * FROM sys.partitions WHERE OBJECT_NAME ([object_id]) = 'TableName'

-- Multiple partition table

-- Optional: create filegroups for partitions
--------------------------------------------------------------------------------------
-- Each partition can be stored on a specific filegroup
ALTER DATABASE DBName
ADD FILEGROUP [FGName]

ALTER DATABASE DBName
ADD FILE
(
    NAME = FGName,
    FILENAME = 'C:\SQLData.FGName.ndf' -- or wherever the filegroup file is located
) TO FILEGROUP [FGName]

-- add subsequent filegroup as required
ALTER DATABASE DBName
ADD FILEGROUP [FGName2]

ALTER DATABASE DBName
ADD FILE
(
    NAME = FGName2,
    FILENAME = 'C:\SQLData.FGName2.ndf'
) TO FILEGROUP [FGName2]
--------------------------------------------------------------------------------------

-- Create the scale out table (name it whatever you want(?))
CREATE TABLE ScaleOut
(
    ID INT
)

-- Insert some data
DECLARE @i INT = 0
WHILE @I <= 1000
BEGIN
    INSERT ScaleOut
    SELECT @i   -- Won't work with VALUE/S ?
    SET @i += 1
END

-- now to create the Partition Function:
--  Sets the boundaries for each of the partitions
--  This function can be used for multiple tables if you want
CREATE PARTITION FUNCTION myRangePF (int)
    AS RANGE LEFT FOR VALUES (500, 1000, 1500); -- this sets the boundary at each of these intervals, in this case creating 4 partitions. 
    -- in this case when it reaches the boundary of 1, it's going to be on the left partition (partition 1) instead of the right partition (partition 2)
    -- when it reaches value 500, it will be on the left partition instead of the right partition
    GO

-- the partition scheme maps boundary values of myRangePF to the filegroups
CREATE PARTITION SCHEME myRangePS
AS PARTITION myRangePF -- specify partition function
TO (FGName, FGName2, FGName3, FGName4); -- list of file groups you want each to go to.
-- First value will be in FG1
-- Second will be in FG2
-- Third will be in FG3
-- Note how FGs outnumber the range in the function? That means any value that goes over the last boundary
-- (in this case, anything over 1500) will overflow into the last FG

-- To apply the partition simply create a clustered index on that table on that partition scheme
CREATE CLUSTERED INDEX clustID -- give the clustered index a name
ON dbo.ScaleOut(ID) -- create it on the table you created before, the parameter is the colum that acts as the index
ON myRangePS(ID) -- create it on the scheme created before, the parameter is the column you want to partition by.

-- Run this to check partition use:
SELECT * FROM sys.partitions WHERE OBJECT_NAME ([object_id]) = 'ScaleOut'



-- How to switch data between partitions
-- Eg take out from partition 4 (archive) to new table
CREATE TABLE ScaleOutArchive
(
    ID INT
) ON [FG4] -- Both tables have to be in the same FileGroup

-- the tables have to be identical, both need to have clustered index in this case
CREATE CLUSTERED INDEX clustID
ON dbo.ScaleOutArchive(ID)

-- Now you can switch out the data
ALTER TABLE TableName
SWITCH PARTITION 4
TO ScaleOutArchive PARTITION 1

-- More on Partition Functions
-- A really good partition boundary scenario is to use dates (20000101, 20010101, 20020101 etc)
-- In this case there are four partitions (to remember how the boundaries create the partitions: 3 dividers will create 4 segments)
-- Because it uses AS RANGE RIGHT: 
-- Anything less than 01 Jan 2000 will be put into the first partition.
-- Anything between 01 Jan 2000 and 01 Jan 2001 will be put in the second partition
-- Anything between 01 Jan 2001 and 01 Jan 2002 will be put in the second partition
-- Everything greater than 01 Jan 2002 will be put in the third partition
CREATE PARTITION FUNCTION PFYears (datetime)
AS RANGE RIGHT
FOR VALUES (20000101, 20010101, 20020101)

-- Map to filegroups
CREATE PARTITION SCHEME PSYears
AS PARTITION PFYears
TO (FG0000, FG2000, FG2001, FG2002, FG2003); -- FG2003 is marked as 'next used'

-- A table is created on a partition scheme using a specified column
CREATE TABLE Sales.Order
(
    OrderDate datetime,
    OrderNo int,
    Customer varchar(50),
    OrderAmount money
) ON PSYears(OrderYear);