-- Implementing In-Memory Objects and Methods
-- Introduced in SS 2014
-- Exam was based on SS 2012, but does cover some new features, mostly concerning In-Memory Objects

-- Buffer Pool Extension
-- Extends SS buffer cache to non-volatile storage
-- Improves performance for read-heavy OLTP workloads
-- more SSD space can be more cost-effective than adding more physical memory (RAM)
--  Public cloud vms with SSDs, particularly SS 2014 Standard Edition
-- Offers a simple configuration with no changes to existing applications

USE master;
GO
ALTER SERVER CONFIGURATION
SET BUFFER POOL EXTENSION ON
(
    FILENAME = 'X:\temp\MyCache.bpe' -- best practice is to put this on a dedicated SSD (very fast, possibly even plugged directly into the motherboard)
    , SIZE = 10GB
);
GO

SELECT * FROM sys.dm_os_buffer_pool_extension_configuration;
-- this dmv will return one row for every page that is held in cache (RAM or non-volatile)