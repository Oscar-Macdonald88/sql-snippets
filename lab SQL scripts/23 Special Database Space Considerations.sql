-- Special Database Space Considerations
-- How to scale out individual tables and how to compress the data (both on disk and in memory)

-- Compression:

--  Row-level 
--      . Simplest
--      . Cheapest on resources
--      . Takes the large fixed-length columns and turns them into variable-length columns
--          - char(10) will always take up 10 characters even if less are used, spacing out unused characters with blanks. 
--          varchar(10) will store up to 10, but each entry will only use as much as required.
--          A common examples would be a notes field with char(1000), but notes would be different for each entry.
--      . Doesn't store 0 or NULL. These aren't big space wasters, but if there are millions of rows then 0 and NULL values take up lots of space

--  Page-level
--      . Includes row-level compression (row-level++)
--      . Takes more resources (not a lot, just a few more CPU ticks. Best to avoid using if CPU use is already > 90%)
--      . Adds prefix and dictionary compression
--          - Prefix compression:
--              . Looks for repeating patterns **at the beginning of values in a given column**. 
--              Removes those values and replaces them with an abbreviated reference. 
--              Eg on Surnames: two values (Wilcox, Wilson) have the same 3 characters at the start, so 'Wil' can be represented
--              with a compressed representation, and 'Wil' is taken to the top of the page and stored with a pointer and a symbol.

--          - Dictionary Compression
--              . Looks for repeating patterns **anywhere on the page**
--              . Removes those values and replaces them with an abbreviated reference, same as prefix compression.

USE Food
-- syntax: 
-- sp_estimate_data_compression_savings 'schemaName', 'tableName', 'index', 'partition', 'typeOfCompression';
-- enter null on index and partition for entire table.
-- enter ROW or PAGE for typeOfCompression
sp_estimate_data_compression_savings 'dbo', 'Snack', NULL, NULL, 'ROW';
-- Look at the 'size_with_current_compression_Setting(KB)' and 'size_with_requested_compression_setting(KB)' and compare
-- Row savings percentage estimate
-- 100 - (size_with_requested_compression_setting(KB) * 100)
DECLARE @Requested INT;
DECLARE @Current INT;
SET @Requested = 0 -- enter size_with_requested_compression_setting(KB) here
SET @Current = 0 -- enter size_with_current_compression_Setting(KB) here
SELECT 100 - ((@Requested * 100) / @Current)

-- Don't enable compression until you find out how much space you will save, and even then it will need to be frequently reviewed!
ALTER TABLE DBName REBUILD PARTITION = ALL
WITH
(
    DATA_COMPRESSION = PAGE -- or ROW
)

-- Before decompressing, ensure you have enough space on disk!
sp_estimate_data_compression_savings 'dbo', 'Snack', NULL, NULL, 'NONE';
-- To decompress:
ALTER TABLE DBName REBUILD PARTITION = ALL
WITH
(
    DATA_COMPRESSION = NONE -- or ROW
)