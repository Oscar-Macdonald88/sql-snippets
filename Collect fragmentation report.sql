-- Create the table

USE [SSLDBA]
GO

/****** Object:  Table [dbo].[tbl_TempFragmentation]    Script Date: 19/10/2021 1:00:10 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbl_TempFragmentation](
	[DatabaseName] [varchar](128) NOT NULL,
	[TableName] [varchar](128) NOT NULL,
	[IndexName] [varchar](100) NOT NULL,
	[FragPercent] [float] NOT NULL,
	[PageCount] [int] NOT NULL,
	[ReportDate] [datetime] NOT NULL
) ON [PRIMARY]
GO

USE [master]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_DBName_TableName]    Script Date: 20/10/2021 4:49:12 PM ******/
CREATE NONCLUSTERED INDEX [IX_DBName_TableName] ON [dbo].[tbl_TempFragmentation]
(
	[DatabaseName] ASC
)
INCLUDE([TableName]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO



--use the correct database
use dbname

insert into SSLDBA..tbl_TempFragmentation
select DB_NAME() as DatabaseName, o.name as [Table Name], i.name as [Index Name], avg_fragmentation_in_percent as [Fragmentation Percentage],
page_count as [Page Count], GETDATE()
from sys.dm_db_index_physical_stats(db_ID(),null,NULL,NULL,'LIMITED') s
join sys.objects o on s.object_id = o.object_id
join sys.indexes i on s.index_id = i.index_id
            and s.object_id = i.object_id
            where page_count > 1000
            and  index_type_desc != 'HEAP'
--          and o.name = 'ACCOUNTINGDISTRIBUTION'
            order by avg_fragmentation_in_percent desc 

-- Use this to populate the job with the required steps
USE [msdb]
GO

declare @tmp_counter int = 1
declare @name nvarchar(128)
declare @temp_step_name nvarchar(128)
declare @num_databases int
select @num_databases = count(0) from master.sys.databases

while @tmp_counter < @num_databases
begin
    select @name = name from master.sys.databases where database_id = @tmp_counter
    select @temp_step_name = N'Gen report for ' + @name
    EXEC msdb.dbo.sp_add_jobstep @job_id=N'5bcd71b6-efe0-4f6a-9f76-c25b75081cf0', @step_name=@temp_step_name, 
            @step_id=@tmp_counter, 
            @cmdexec_success_code=0, 
            @on_success_action=3, 
            @on_fail_action=3, 
            @retry_attempts=3, 
            @retry_interval=1, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=N'insert into master..tbl_TempFragmentation
    select DB_NAME() as DatabaseName, o.name as [Table Name], i.name as [Index Name], avg_fragmentation_in_percent as [Fragmentation Percentage],
    page_count as [Page Count], GETDATE()
    from sys.dm_db_index_physical_stats(db_ID(),null,NULL,NULL,''LIMITED'') s
    join sys.objects o on s.object_id = o.object_id
    join sys.indexes i on s.index_id = i.index_id
                and s.object_id = i.object_id
                where page_count > 1000
                and  index_type_desc != ''HEAP''
                order by avg_fragmentation_in_percent desc ', 
            @database_name=@name,
            @flags=0
    set @tmp_counter = @tmp_counter + 1
end
go
