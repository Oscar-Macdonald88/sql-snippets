-- Managing Partitioned Tables

-- Split Partitions
-- Add a new boundary to split a single partition into two
-- Eg from the Table partitioning example, create a new partition for 2003 orders:
ALTER PARTITION FUNCTION PFYears()
SPLIT RANGE (20030101);

-- Merge Partitions
-- Removes a boundary to turn two partitions into a single partition
-- Eg merge 2000 and pre-2000 orders
ALTER PARTITION FUNCTION PFYears()
MERGE RANGE (20000101);

-- Switch Partitions
-- Either between two partitioned tables, or one partitioned and one non-partitioned table
-- Eg switch partition containing old orders to a staging table for archiving
-- They must be in the same file group in order to switch
ALTER TABLE Sales.Order
SWITCH PARTITION $PARTITION.PFYears(20000101) -- using $ identifies which partitions you want to switch(?)
TO archive_staging_table;