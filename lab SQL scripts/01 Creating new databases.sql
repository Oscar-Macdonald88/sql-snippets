-- SQl Server Basic Database Objects
-- Start with new SQL Server install
-- Create new Database using SSMS.
-- Don't forget your ON statement is comma separated!
create database Food on (
	Name = FoodData1, -- logical name or friendly name
	FileName = 'c:\Program Files\Microsoft SQL Server\MSSQL14.SSL_DEVELOPER\MSSQL\DATA\FoodData1.mdf', -- physical name or path name
	-- these are like physical addresses and DNS addresses, if the FileName is altered, nobody needs to change their entry for Name
	size = 10 MB, -- options are KB, MB, GB, TB
	maxsize = unlimited,
	filegrowth = 1 GB
	) LOG on (
	Name = FoodLog1, -- logical name or friendly name
	FileName = 'c:\Program Files\Microsoft SQL Server\MSSQL14.SSL_DEVELOPER\MSSQL\DATA\FoodLog1.ldf', -- physical name or path name
	-- these are like physical addresses and DNS addresses, if the FileName is altered, nobody needs to change their entry for Name
	size = 10 MB, -- options are KB, MB, GB, TB
	maxsize = unlimited,
	filegrowth = 1024 MB -- 1024MB = 1GB
	)

-- the following script was generated from SSMS:
create database [DatabaseName] CONTAINMENT = NONE on primary (
	NAME = N'DatabaseName',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SSL_DEVELOPER\MSSQL\DATA\DatabaseName.mdf',
	SIZE = 8192 KB,
	FILEGROWTH = 10 %
	) LOG on (
	NAME = N'DatabaseName_log',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SSL_DEVELOPER\MSSQL\DATA\DatabaseName_log.ldf',
	SIZE = 8192 KB,
	FILEGROWTH = 10 %
	)
go

alter database [DatabaseName]

set COMPATIBILITY_LEVEL = 140
go

alter database [DatabaseName]

set ANSI_NULL_DEFAULT off
go

alter database [DatabaseName]

set ansi_nulls off
go

alter database [DatabaseName]

set ansi_padding off
go

alter database [DatabaseName]

set ansi_warnings off
go

alter database [DatabaseName]

set arithabort off
go

alter database [DatabaseName]

set AUTO_CLOSE off
go

alter database [DatabaseName]

set AUTO_SHRINK off
go

alter database [DatabaseName]

set AUTO_CREATE_STATISTICS on (INCREMENTAL = off)
go

alter database [DatabaseName]

set AUTO_UPDATE_STATISTICS on
go

alter database [DatabaseName]

set cursor_close_on_commit off
go

alter database [DatabaseName]

set CURSOR_DEFAULT global
go

alter database [DatabaseName]

set concat_null_yields_null off
go

alter database [DatabaseName]

set numeric_roundabort off
go

alter database [DatabaseName]

set quoted_identifier off
go

alter database [DatabaseName]

set RECURSIVE_TRIGGERS off
go

alter database [DatabaseName]

set DISABLE_BROKER
go

alter database [DatabaseName]

set AUTO_UPDATE_STATISTICS_ASYNC off
go

alter database [DatabaseName]

set DATE_CORRELATION_OPTIMIZATION off
go

alter database [DatabaseName]

set parameterization simple
go

alter database [DatabaseName]

set READ_COMMITTED_SNAPSHOT off
go

alter database [DatabaseName]

set READ_WRITE
go

alter database [DatabaseName]

set RECOVERY full -- Full, Bulk-logged or simple
go

alter database [DatabaseName]

set MULTI_USER
go

alter database [DatabaseName]

set PAGE_VERIFY CHECKSUM
go

alter database [DatabaseName]

set TARGET_RECOVERY_TIME = 60 SECONDS
go

alter database [DatabaseName]

set DELAYED_DURABILITY = DISABLED
go

use [DatabaseName]
go

alter database SCOPED CONFIGURATION

set LEGACY_CARDINALITY_ESTIMATION = off;
go

alter database SCOPED CONFIGURATION
for SECONDARY

set LEGACY_CARDINALITY_ESTIMATION = primary;
go

alter database SCOPED CONFIGURATION

set maxdop = 0;
go

alter database SCOPED CONFIGURATION
for SECONDARY

set maxdop = primary;
go

alter database SCOPED CONFIGURATION

set PARAMETER_SNIFFING = on;
go

alter database SCOPED CONFIGURATION
for SECONDARY

set PARAMETER_SNIFFING = primary;
go

alter database SCOPED CONFIGURATION

set QUERY_OPTIMIZER_HOTFIXES = off;
go

alter database SCOPED CONFIGURATION
for SECONDARY

set QUERY_OPTIMIZER_HOTFIXES = primary;
go

use [DatabaseName]
go

if not exists (
		select name
		from sys.filegroups
		where is_default = 1
			and name = N'PRIMARY'
		)
	alter database [DatabaseName] MODIFY FILEGROUP [PRIMARY] default
go


