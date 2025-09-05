--Query Toolset Backups and Maantenance
Declare @CommandType nvarchar(50)

/* Uncomment Required Command Type */
--Set @CommandType = 'BACKUP_DATABASE' 
--Set @CommandType = 'BACKUP_LOG'
--Set @CommandType = 'DBCC_CHECKDB' 
--Set @CommandType = 'ALTER_INDEX'
--Set @CommandType = 'UPDATE_STATISTICS' 
--Set @CommandType = 'RESTORE_VERIFYONLY'
--Set @CommandType = 'xp_create_subdir'
--Set @CommandType = 'xp_delete_file'

SELECT 
    DatabaseName, 
    Command, 
    CommandType, 
    StartTime, 
    EndTime, 
    CONVERT(VARCHAR, DATEDIFF(SECOND, StartTime, EndTime) / 86400) + ':' +
    RIGHT('0' + CONVERT(VARCHAR, (DATEDIFF(SECOND, StartTime, EndTime) % 86400) / 3600), 2) + ':' +
    RIGHT('0' + CONVERT(VARCHAR, (DATEDIFF(SECOND, StartTime, EndTime) % 3600) / 60), 2) + ':' +
    RIGHT('0' + CONVERT(VARCHAR, DATEDIFF(SECOND, StartTime, EndTime) % 60), 2) AS 'Duration (D:HH:MM:SS)', 
    ErrorNumber 
FROM 
    DBAToolset.dbo.CommandLog

Where 1=1
and CommandType = @CommandType

--and DatabaseName = '' --Enter single DB Name
--and DatabaseName in ('','','') -- Enter multiple database names
--and ErrorNumber > 0 -- Uncomment to get errors.
--and StartTime between '' and ''
order by StartTime desc 
GO

