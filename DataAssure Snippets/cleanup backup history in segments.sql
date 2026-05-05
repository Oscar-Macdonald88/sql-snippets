declare @retentionDays int = datediff(day, (select top 1 backup_start_date from msdb..backupset order by backup_start_date), getdate())
declare @intervalDays int = 40
declare @minRetentionDays int = 60

select @retentionDays

while @retentionDays > @minRetentionDays
begin
	update [dsl].[tbl_ToolsetConfig]
	set IntValue = @retentionDays
	where ConfigOption = 'RetentionMSDBBackupHistory'

	exec [dsl].[up_PerformCleanupMSDB]
	-- if msdb is in full recovery mode and log backups are absolutely required, take log backups in between cleanup.
	-- Check the CommandLog to get the format of the DatabaseBackup stored procedure and replace+uncomment this line:
	--exec [DBAToolset].[dbo].[DatabaseBackup] @Databases = 'msdb', @BackupType = 'LOG', @Verify = 'Y', @CleanupTime = 48, @CleanupMode = 'BEFORE_BACKUP', @Compress = 'Y', @CopyOnly = 'N', @ChangeBackupType = 'Y', @BackupSoftware = NULL, @CheckSum = 'Y', @BlockSize = NULL, @BufferCount = NULL, @MaxTransferSize = NULL, @NumberOfFiles = 1, @MinBackupSizeForMultipleFiles = NULL, @MaxFileSize = NULL, @CompressionLevel = NULL, @Description = 'DBAToolset Backup', @Threads = NULL, @Throttle = NULL, @Encrypt = 'N', @EncryptionAlgorithm = NULL, @ServerCertificate = NULL, @ServerAsymmetricKey = NULL, @EncryptionKey = NULL, @ReadWriteFileGroups = 'N', @OverrideBackupPreference = 'N', @NoRecovery = 'N', @URL = NULL, @Credential = NULL, @MirrorDirectory = NULL, @MirrorCleanupTime = NULL, @MirrorCleanupMode = 'AFTER_BACKUP', @MirrorURL = NULL, @AvailabilityGroups = NULL, @Updateability = 'ALL', @AdaptiveCompression = NULL, @ModificationLevel = NULL, @LogSizeSinceLastLogBackup = NULL, @TimeSinceLastLogBackup = NULL, @DataDomainBoostHost = NULL, @DataDomainBoostUser = NULL, @DataDomainBoostDevicePath = NULL, @DataDomainBoostLockboxPath = NULL, @DirectoryStructure = '{DatabaseName}_{BackupType}', @AvailabilityGroupDirectoryStructure = '{DatabaseName}_{BackupType}', @FileName = '{DatabaseName}_{BackupType}_{Partial}_{CopyOnly}_{Year}{Month}{Day}_{Hour}{Minute}{Second}_{FileNumber}.{FileExtension}', @AvailabilityGroupFileName = '{DatabaseName}_{BackupType}_{Partial}_{CopyOnly}_{Year}{Month}{Day}_{Hour}{Minute}{Second}_{FileNumber}.{FileExtension}', @FileExtensionFull = NULL, @FileExtensionDiff = NULL, @FileExtensionLog = NULL, @Init = 'N', @Format = 'N', @ObjectLevelRecoveryMap = 'N', @ExcludeLogShippedFromLogBackup = 'Y', @StringDelimiter = ',', @DatabaseOrder = NULL, @DatabasesInParallel = 'N', @LogToTable = 'Y', @Execute = 'Y'

	set @retentionDays = @retentionDays - @intervalDays
end