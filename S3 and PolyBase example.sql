-- Enable PolyBase in sp_configure:
exec sp_configure @configname = 'polybase enabled', @configvalue = 1
;
RECONFIGURE
;
exec sp_configure @configname = 'polybase enabled'
;
-- Create the database
DROP DATABASE IF EXISTS temp_accounts;
GO
CREATE DATABASE temp_accounts;
GO
USE [temp_accounts];
GO
-- Create a database scoped credential
IF NOT EXISTS(SELECT * FROM sys.credentials WHERE name = 's3_dc')
BEGIN
 CREATE DATABASE SCOPED CREDENTIAL s3_dc
 WITH IDENTITY = 'S3 Access Key',
 SECRET = '<AccessKeyID>:<SecretKeyID>' ;
END
GO
-- Create an external data source
CREATE EXTERNAL DATA SOURCE s3_ds
WITH
(   LOCATION = 's3://<ip_address>:<port>/'
,   CREDENTIAL = s3_dc
);
GO
-- Create some sample data to export
DROP TABLE IF EXISTS [temp_accounts].[dbo].[Accounts];
CREATE TABLE [temp_accounts].[dbo].[Accounts]
(
    AccountNumber varchar(10) NOT NULL PRIMARY KEY,
    Phone1 varchar(20) NULL,
    Phone2 varchar(20) NULL,
    Phone3 varchar(20) NULL
);
INSERT INTO [temp_accounts].[dbo].[Accounts]
        (AccountNumber, Phone1, Phone2, Phone3)
VALUES  ('AW29825', '(123)456-7890', '(123)567-8901', NULL),
        ('AW73565', '(234)0987-654', NULL, NULL);

-- External File Format for PARQUET
CREATE EXTERNAL FILE FORMAT ParquetFileFormat WITH(FORMAT_TYPE = PARQUET);
GO
-- Use CREATE EXTERNAL TABLE AS SELECT exporting data to a parquet file
CREATE EXTERNAL TABLE ext_accounts
WITH 
(   LOCATION = '/cetas/accounts.parquet',
    DATA_SOURCE = s3_ds,  
    FILE_FORMAT = ParquetFileFormat
) AS SELECT * FROM [temp_accounts].[dbo].[Accounts]